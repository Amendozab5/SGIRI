import { Component, OnInit, ChangeDetectorRef, NgZone, ViewChild, ElementRef, AfterViewChecked } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ActivatedRoute, RouterModule } from '@angular/router';
import { TicketService } from '../../_services/ticket.service';
import { FormsModule } from '@angular/forms';
import { TokenStorageService } from '../../_services/token-storage.service';

@Component({
    selector: 'app-ticket-detail',
    standalone: true,
    imports: [CommonModule, RouterModule, FormsModule],
    templateUrl: './ticket-detail.component.html',
    styleUrls: ['./ticket-detail.component.css']
})
export class TicketDetailComponent implements OnInit, AfterViewChecked {
    @ViewChild('chatFeed') private chatFeed!: ElementRef;

    ticket: any = null;
    loading = true;
    isSubmitting = false;
    successMessage = '';
    error = '';
    commentText = '';
    currentUser: any = null;
    showStatusUpdate = false;
    isCliente = false;
    backRoute = '/home/user';

    // Rating state
    ratingValue = 0;
    hoverRating = 0;
    ratingComment = '';
    ratingSubmitting = false;
    ratingError = '';
    ratingSuccess = false;

    // Status modal state
    showConfirmModal = false;
    modalData = {
        title: '',
        status: '',
        observation: '',
        confirmText: ''
    };

    constructor(
        private route: ActivatedRoute,
        private ticketService: TicketService,
        private tokenService: TokenStorageService,
        private cdr: ChangeDetectorRef,
        private zone: NgZone
    ) { }

    ngAfterViewChecked(): void {
        this.scrollToBottom();
    }

    private scrollToBottom(): void {
        try {
            if (this.chatFeed) {
                this.chatFeed.nativeElement.scrollTop = this.chatFeed.nativeElement.scrollHeight;
            }
        } catch (err) { }
    }

    ngOnInit(): void {
        this.currentUser = this.tokenService.getUser();
        const id = this.route.snapshot.paramMap.get('id');
        if (id) {
            this.loadTicket(+id);
        }
    }

    loadTicket(id: number): void {
        this.loading = true;
        this.cdr.detectChanges();
        this.ticketService.getTicketById(id).subscribe({
            next: (data) => {
                this.zone.run(() => {
                    this.ticket = data;
                    this.loading = false;
                    this.checkPermissions();
                    this.cdr.detectChanges();
                });
            },
            error: (err) => {
                this.zone.run(() => {
                    this.error = 'No se pudo cargar el detalle del ticket.';
                    this.loading = false;
                    this.cdr.detectChanges();
                    console.error(err);
                });
            }
        });
    }

    checkPermissions(): void {
        if (!this.currentUser) return;
        const roles = this.currentUser.roles || [];
        this.zone.run(() => {
            this.showStatusUpdate = roles.includes('ROLE_TECNICO') ||
                roles.includes('ROLE_ADMIN') ||
                roles.includes('ROLE_ADMIN_MASTER') ||
                roles.includes('ROLE_ADMIN_TECNICOS');

            this.isCliente = roles.includes('ROLE_CLIENTE');

            if (roles.includes('ROLE_ADMIN') || roles.includes('ROLE_ADMIN_MASTER') ||
                roles.includes('ROLE_ADMIN_TECNICOS') || roles.includes('ROLE_ADMIN_VISUAL')) {
                this.backRoute = '/home/asignacion-tickets';
            } else if (roles.includes('ROLE_TECNICO')) {
                this.backRoute = '/home/tech-tickets';
            } else {
                this.backRoute = '/home/user';
            }

            this.cdr.detectChanges();
        });
    }

    addComment(): void {
        if (!this.commentText.trim()) return;
        this.isSubmitting = true;
        this.cdr.detectChanges();
        this.ticketService.addComment(this.ticket.idTicket, this.commentText).subscribe({
            next: () => {
                this.zone.run(() => {
                    this.commentText = '';
                    this.loadTicket(this.ticket.idTicket);
                    this.isSubmitting = false;
                    this.cdr.detectChanges();
                });
            },
            error: (err) => {
                this.zone.run(() => {
                    console.error(err);
                    this.isSubmitting = false;
                    this.cdr.detectChanges();
                });
            }
        });
    }

    onKeyEnter(event: any): void {
        if (!event.shiftKey) {
            event.preventDefault();
            this.addComment();
        }
    }

    // ─── Rating helpers ────────────────────────────────────────────────────────

    get isTicketClosed(): boolean {
        const code = this.ticket?.estadoItem?.codigo;
        return code === 'CERRADO' || code === 'RESUELTO';
    }

    get canRate(): boolean {
        return this.isCliente && this.isTicketClosed && !this.ticket?.calificacionSatisfaccion;
    }

    get alreadyRated(): boolean {
        return this.isCliente && this.isTicketClosed && !!this.ticket?.calificacionSatisfaccion;
    }

    setRating(stars: number): void { this.ratingValue = stars; }
    setHover(stars: number): void { this.hoverRating = stars; }
    clearHover(): void { this.hoverRating = 0; }

    getStarClass(star: number): string {
        const effective = this.hoverRating > 0 ? this.hoverRating : this.ratingValue;
        return star <= effective ? 'rating-star filled' : 'rating-star';
    }

    getDisplayStarClass(star: number): string {
        return star <= (this.ticket?.calificacionSatisfaccion || 0) ? 'rating-star filled' : 'rating-star';
    }

    starsArray = [1, 2, 3, 4, 5];

    submitRating(): void {
        if (this.ratingValue === 0) {
            this.ratingError = 'Por favor selecciona una puntuación de 1 a 5 estrellas.';
            return;
        }
        this.ratingSubmitting = true;
        this.ratingError = '';
        this.cdr.detectChanges();

        this.ticketService.rateTicket(
            this.ticket.idTicket,
            this.ratingValue,
            this.ratingComment.trim() || undefined
        ).subscribe({
            next: () => {
                this.zone.run(() => {
                    this.ratingSuccess = true;
                    this.ratingSubmitting = false;
                    this.ratingValue = 0;
                    this.ratingComment = '';
                    this.loadTicket(this.ticket.idTicket);
                    this.cdr.detectChanges();
                });
            },
            error: (err) => {
                this.zone.run(() => {
                    this.ratingError = err?.error?.message || 'Error al enviar la calificación.';
                    this.ratingSubmitting = false;
                    this.cdr.detectChanges();
                });
            }
        });
    }

    // ─── Status modal ─────────────────────────────────────────────────────────

    openConfirmModal(statusCode: string): void {
        this.modalData.status = statusCode;
        this.modalData.observation = '';

        switch (statusCode) {
            case 'EN_PROCESO':
                this.modalData.title = 'Atender Incidencia';
                this.modalData.confirmText = 'Comenzar a atender';
                break;
            case 'RESUELTO':
                this.modalData.title = 'Resolver Incidencia';
                this.modalData.confirmText = 'Marcar como resuelto';
                break;
            case 'REQUIERE_VISITA':
                this.modalData.title = 'Solicitar Visita Técnica';
                this.modalData.confirmText = 'Solicitar visita';
                break;
            case 'CERRADO':
                this.modalData.title = 'Cerrar Ticket';
                this.modalData.confirmText = 'Cerrar permanentemente';
                break;
        }

        this.showConfirmModal = true;
    }

    onConfirmAction(): void {
        this.showConfirmModal = false;
        this.loading = true;
        this.cdr.detectChanges();

        this.ticketService.updateStatus(
            this.ticket.idTicket,
            this.modalData.status,
            this.modalData.observation
        ).subscribe({
            next: () => {
                this.zone.run(() => {
                    this.successMessage = 'Estado actualizado correctamente.';
                    setTimeout(() => this.successMessage = '', 4000);
                    this.loadTicket(this.ticket.idTicket);
                    this.cdr.detectChanges();
                });
            },
            error: () => {
                this.zone.run(() => {
                    this.error = 'Error al actualizar el estado.';
                    this.loading = false;
                    this.cdr.detectChanges();
                });
            }
        });
    }

    changeStatus(statusCode: string): void {
        this.openConfirmModal(statusCode);
    }

    getStatusBadgeClass(status: string): string {
        switch (status?.toUpperCase()) {
            case 'ABIERTO': return 'bg-info-subtle text-info';
            case 'ASIGNADO': return 'bg-primary-subtle text-primary';
            case 'EN_PROCESO': return 'bg-warning-subtle text-warning';
            case 'RESUELTO':
            case 'CERRADO': return 'bg-success-subtle text-success';
            case 'REQUIERE_VISITA': return 'bg-danger-subtle text-danger';
            default: return 'bg-secondary-subtle text-secondary';
        }
    }
}
