import { Component, OnInit, ChangeDetectorRef, NgZone } from '@angular/core';
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
export class TicketDetailComponent implements OnInit {
    ticket: any = null;
    loading = true;
    error = '';
    commentText = '';
    isSubmitting = false;
    currentUser: any = null;
    showStatusUpdate = false;

    constructor(
        private route: ActivatedRoute,
        private ticketService: TicketService,
        private tokenService: TokenStorageService,
        private cdr: ChangeDetectorRef,
        private zone: NgZone
    ) { }

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
        const roles = this.currentUser.roles;
        this.zone.run(() => {
            this.showStatusUpdate = roles.includes('ROLE_TECNICO') ||
                roles.includes('ROLE_ADMIN_MASTER') ||
                roles.includes('ROLE_ADMIN_TECNICOS');
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

    changeStatus(statusCode: string): void {
        const obs = prompt('Ingrese una observación para el cambio de estado (opcional):');
        if (obs === null) return; // Cancelled

        this.loading = true;
        this.cdr.detectChanges();
        this.ticketService.updateStatus(this.ticket.idTicket, statusCode, obs).subscribe({
            next: () => {
                this.zone.run(() => {
                    this.loadTicket(this.ticket.idTicket);
                    this.cdr.detectChanges();
                });
            },
            error: (err) => {
                this.zone.run(() => {
                    this.error = 'Error al actualizar el estado.';
                    this.loading = false;
                    this.cdr.detectChanges();
                });
            }
        });
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
