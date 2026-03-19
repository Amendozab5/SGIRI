import { Component, OnInit, ChangeDetectorRef, NgZone, ViewChild, ElementRef, AfterViewChecked, OnDestroy } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ActivatedRoute, Router, RouterModule } from '@angular/router';
import { TicketService } from '../../_services/ticket.service';
import { FormsModule } from '@angular/forms';
import { TokenStorageService } from '../../_services/token-storage.service';
import { HttpClient } from '@angular/common/http';
import { VisitaService } from '../../_services/visita.service';

import { MasterDataService } from '../../_services/master-data.service';

@Component({
    selector: 'app-ticket-detail',
    standalone: true,
    imports: [CommonModule, RouterModule, FormsModule],
    templateUrl: './ticket-detail.component.html',
    styleUrls: ['./ticket-detail.component.css']
})
export class TicketDetailComponent implements OnInit, AfterViewChecked, OnDestroy {
    @ViewChild('chatFeed') private chatFeed!: ElementRef;

    ticket: any = null;
    loading = true;
    isSubmitting = false;
    successMessage = '';
    error = '';
    commentText = '';
    currentUser: any = null;
    showStatusUpdate = false;
    isOnlyTecnico = false;
    isCliente = false;
    isTecnico = false;
    backRoute = '/home/user';
    visits: any[] = [];

    // Rating state
    ratingValue = 0;
    hoverRating = 0;
    ratingComment = '';
    ratingSubmitting = false;
    ratingError = '';
    ratingSuccess = false;

    // Chat modal and unread notification state
    isChatOpen = false;
    unreadCount = 0;

    // Status modal state
    showConfirmModal = false;
    modalData = {
        title: '',
        status: '',
        observation: '',
        confirmText: ''
    };

    // Reassign modal state
    showReassignModal = false;
    reassignData = {
        userId: 0,
        notaReasignacion: ''
    };
    technicians: any[] = [];
    reassignSearchTerm: string = '';
    selectedTechForPreview: any = null;
    loadingTechnicians = false;

    // ─── Tech Work Form State ──────────────────────────────────────────────────
    formStep: number = 1; // 1: selections, 2: result/comments
    searchTerm: string = '';
    searchCategory: string = ''; // 'implementos', 'problemas', 'soluciones', 'pruebas'
    inventorySearchTerm: string = '';

    // Frequency data for dynamic coloring
    frecuencias: any = null;

    // Inventory items from backend
    availableInventario: any[] = [];
    filteredInventoryList: any[] = [];
    selectedInventario: any[] = []; // { idItemInventario, nombre, cantidad }

    // Existing informe (loaded from backend)
    informeTecnico: any = null; // Latest report
    historialInformes: any[] = []; // All reports
    inventarioUsado: any[] = [];
    loadingInforme = false;

    // Form submission
    techFormSubmitting = false;
    techFormSuccess = false;
    techFormError = '';

    // Active tab (Stage 2)
    techFormTab: 'RESUELTO' | 'NO_RESUELTO' = 'RESUELTO';

    // Selections
    selectedImplementos: string[] = [];
    selectedProblemas: string[] = [];
    selectedSoluciones: string[] = [];
    selectedPruebas: string[] = [];

    // NO_RESUELTO branch
    selectedMotivo: string = '';
    comentarioTecnico: string = '';
    tiempoTrabajo: number = 30;
    implementosOpciones: string[] = [];
    problemasOpciones: string[] = [];
    solucionesOpciones: string[] = [];
    pruebasOpciones: string[] = [];
    motivosNoResolucion: string[] = [];

    starsArray = [1, 2, 3, 4, 5];
    private timerInterval: any;
    elapsedTimeDisplay: string = '00:00:00';

    constructor(
        private route: ActivatedRoute,
        private ticketService: TicketService,
        private visitaService: VisitaService,
        private tokenService: TokenStorageService,
        private masterDataService: MasterDataService,
        private router: Router,
        private cdr: ChangeDetectorRef,
        private zone: NgZone
    ) { }

    ngAfterViewChecked(): void {
        this.scrollToBottom();
    }

    private scrollToBottom(): void {
        try {
            if (this.chatFeed && this.isChatOpen) {
                this.chatFeed.nativeElement.scrollTop = this.chatFeed.nativeElement.scrollHeight;
            }
        } catch (err) { }
    }

    ngOnInit(): void {
        this.currentUser = this.tokenService.getUser();
        this.checkPermissions(); // Set showStatusUpdate, isTecnico, etc. BEFORE loading data
        this.resetTechForm();

        const id = this.route.snapshot.paramMap.get('id');
        if (id) {
            this.loadTicket(+id);
            this.loadVisitHistory(+id);
        }
        if (this.isTecnico || (this.currentUser && this.currentUser.roles?.includes('ROLE_ADMIN_MASTER'))) {
            this.loadFrecuencias();
            this.loadAvailableInventario();
            this.loadCatalogos();
        }
    }

    ngOnDestroy(): void {
        this.stopTimer();
    }

    loadVisitHistory(ticketId: number) {
        this.visitaService.getVisitaHistory(ticketId).subscribe({
            next: (data) => {
                this.visits = data;
                this.cdr.detectChanges();
            },
            error: (err) => console.error('Error loading visit history', err)
        });
    }

    loadCatalogos() {
        this.masterDataService.getCatalogoItems('IMPLEMENTOS_TECNICOS', true).subscribe(
            res => { this.implementosOpciones = res.map((r: any) => r.nombre); this.updateGeneralFilters(); }
        );
        this.masterDataService.getCatalogoItems('PROBLEMAS_TECNICOS', true).subscribe(
            res => { this.problemasOpciones = res.map((r: any) => r.nombre); this.updateGeneralFilters(); }
        );
        this.masterDataService.getCatalogoItems('SOLUCIONES_TECNICAS', true).subscribe(
            res => { this.solucionesOpciones = res.map((r: any) => r.nombre); this.updateGeneralFilters(); }
        );
        this.masterDataService.getCatalogoItems('PRUEBAS_TECNICAS', true).subscribe(
            res => { this.pruebasOpciones = res.map((r: any) => r.nombre); this.updateGeneralFilters(); }
        );
        this.masterDataService.getCatalogoItems('MOTIVOS_NO_RESOLUCION_TECNICA', true).subscribe(
            res => this.motivosNoResolucion = res.map((r: any) => r.nombre)
        );
    }

    loadAvailableInventario() {
        this.ticketService.getAvailableInventario().subscribe({
            next: (data) => {
                this.availableInventario = data;
                this.updateInventoryFilter();
            },
            error: (err) => console.error('Error loading inventario', err)
        });
    }

    loadFrecuencias() {
        this.ticketService.getFrecuencias().subscribe({
            next: (data) => this.frecuencias = data,
            error: (err) => console.error('Error loading frequencies', err)
        });
    }

    loadTicket(id: number): void {
        this.loading = true;
        this.cdr.detectChanges();
        this.ticketService.getTicketById(id).subscribe({
            next: (data) => {
                this.zone.run(() => {
                    this.ticket = data;
                    
                    // Refresh agenda state first
                    this.visitaService.getVisitaHistory(id).subscribe({
                        next: (visitsData) => {
                            this.visits = visitsData;
                            this.loading = false;
                            this.loadInformeTecnico(id);
                            this.calculateUnreadMessages(id);
                            this.handleTimerLogic();
                            this.cdr.detectChanges();
                        },
                        error: (err) => {
                            console.error('Error loading visit history', err);
                            this.loading = false;
                            this.cdr.detectChanges();
                        }
                    });
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

    loadInformeTecnico(ticketId: number): void {
        this.loadingInforme = true;

        // Load all reports
        this.ticketService.getInforme(ticketId).subscribe({
            next: (data) => {
                this.zone.run(() => {
                    if (Array.isArray(data)) {
                        this.historialInformes = data;
                        this.informeTecnico = data.length > 0 ? data[0] : null;
                    } else {
                        this.informeTecnico = data;
                        this.historialInformes = data ? [data] : [];
                    }
                    this.loadingInforme = false;
                    this.cdr.detectChanges();
                });
            },
            error: (err) => {
                this.zone.run(() => {
                    this.informeTecnico = null;
                    this.historialInformes = [];
                    this.loadingInforme = false;
                    this.cdr.detectChanges();
                });
            }
        });

        // Load used inventory items
        this.ticketService.getInventarioUsado(ticketId).subscribe({
            next: (items) => {
                this.zone.run(() => {
                    this.inventarioUsado = items;
                    this.cdr.detectChanges();
                });
            },
            error: () => this.inventarioUsado = []
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

            this.isTecnico = roles.includes('ROLE_TECNICO');
            this.isOnlyTecnico = roles.includes('ROLE_TECNICO') && !roles.includes('ROLE_ADMIN_MASTER') && !roles.includes('ROLE_ADMIN');

            this.isCliente = roles.includes('ROLE_CLIENTE');

            if (roles.includes('ROLE_ADMIN') || roles.includes('ROLE_ADMIN_MASTER') ||
                roles.includes('ROLE_ADMIN_TECNICOS') || roles.includes('ROLE_ADMIN_CONTRATOS')) {
                this.backRoute = '/home/asignacion-tickets';
            } else if (roles.includes('ROLE_TECNICO')) {
                this.backRoute = '/home/tech-tickets';
            } else {
                this.backRoute = '/home/user';
            }

            this.cdr.detectChanges();
        });
    }

    get isAdmin(): boolean {
        if (!this.currentUser) return false;
        const roles = this.currentUser.roles || [];
        return roles.includes('ROLE_ADMIN_MASTER') || 
               roles.includes('ROLE_ADMIN_TECNICOS') || 
               roles.includes('ROLE_ADMIN');
    }

    get isAdminMaster(): boolean {
        return !!this.currentUser?.roles?.includes('ROLE_ADMIN_MASTER');
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

    // ─── Chat Notifications Logic ──────────────────────────────────────────

    calculateUnreadMessages(ticketId: number): void {
        const totalComments = this.ticket?.comentarios?.length || 0;
        const userKey = this.currentUser?.username || 'guest';
        const storageKey = `ticket_${ticketId}_read_count_${userKey}`;

        if (this.isChatOpen) {
            this.unreadCount = 0;
            localStorage.setItem(storageKey, totalComments.toString());
        } else {
            const savedCount = parseInt(localStorage.getItem(storageKey) || '0', 10);

            if (totalComments > savedCount) {
                // If there are new comments, count the ones NOT from the current user
                let newUnread = 0;
                for (let i = savedCount; i < totalComments; i++) {
                    const comment = this.ticket.comentarios[i];
                    if (comment.usuario?.username !== this.currentUser?.username) {
                        newUnread++;
                    }
                }
                this.unreadCount = newUnread;
            } else {
                this.unreadCount = 0;
            }
        }
    }

    toggleChat(): void {
        this.isChatOpen = !this.isChatOpen;
        if (this.isChatOpen) {
            // Give the view time to render before scrolling to bottom
            setTimeout(() => this.scrollToBottom(), 100);

            // Re-calculate and reset unread counts when chat is opened
            this.calculateUnreadMessages(this.ticket.idTicket);
        }
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

    get canAssign(): boolean {
        if (!this.currentUser || !this.ticket) return false;
        const status = this.ticket.estadoItem?.codigo;
        // Administrator can: Assign tickets (usually ABIERTO or specifically REPROGRAMADA)
        return this.isAdmin && (status === 'ABIERTO');
    }

    get canReassign(): boolean {
        if (!this.isAdmin || !this.ticket) return false;
        const status = this.ticket.estadoItem?.codigo;
        return status === 'ASIGNADO' || status === 'REPROGRAMADA' || status === 'REQUIERE_VISITA';
    }

    get canClose(): boolean {
        if (!this.isAdmin || !this.ticket) return false;
        const status = this.ticket.estadoItem?.codigo;
        // Administrator verification required -> only if status = RESUELTO
        return status === 'RESUELTO';
    }

    get isAssignedToMe(): boolean {
        if (!this.ticket || !this.currentUser) return false;
        const userId = this.currentUser.id || this.currentUser.userId;
        const assignedId = this.ticket.idUsuarioAsignado || this.ticket.usuarioAsignado?.id;
        return userId === assignedId;
    }

    get canAttend(): boolean {
        if (this.showOnlyCancellationNotice) return false;
        if (!this.ticket || !this.currentUser) return false;
        const status = this.ticket.estadoItem?.codigo;
        
        // 3. ADMIN MUST NOT SEE "ATENDER" (includes Master Admin)
        if (this.isAdmin || this.isAdminMaster) return false;

        if (this.isOnlyTecnico || this.currentUser.roles?.includes('ROLE_TECNICO')) {
            // For REQUIERE_VISITA, technician can only attend if there's an active scheduled visit
            if (status === 'REQUIERE_VISITA') {
                return this.isAssignedToMe && this.hasActiveScheduledVisit();
            }
            return ((status === 'ASIGNADO') && this.isAssignedToMe) || (status === 'ABIERTO');
        }
        return false;
    }

    get showPendingSchedulingNotice(): boolean {
        if (!this.ticket || !this.currentUser) return false;
        const status = this.ticket.estadoItem?.codigo;
        // Only show for technicians when REQUIERE_VISITA but no active scheduled visit
        if (status === 'REQUIERE_VISITA' && this.isAssignedToMe && (this.isOnlyTecnico || this.currentUser.roles?.includes('ROLE_TECNICO'))) {
            return !this.hasActiveScheduledVisit();
        }
        return false;
    }

    private hasActiveScheduledVisit(): boolean {
        if (!this.visits?.length) return false;
        // Check if there's at least one visit that is not cancelled and has date/time
        return this.visits.some(v => 
            v.estado?.codigo !== 'CANCELADA' && 
            v.fechaVisita && 
            v.horaInicio
        );
    }

    get isTicketCanceled(): boolean {
        return this.ticket?.estadoItem?.codigo === 'CANCELADA';
    }

    get isVisitRequestCanceled(): boolean {
        if (!this.ticket || this.ticket.estadoItem?.codigo !== 'REQUIERE_VISITA') return false;
        if (!this.visits?.length) return false;

        const hasCancelled = this.visits.some(v => v.estado?.codigo === 'CANCELADA');
        const hasActive = this.visits.some(v => v.estado?.codigo !== 'CANCELADA');

        return hasCancelled && !hasActive;
    }

    get showOnlyCancellationNotice(): boolean {
        return this.isTicketCanceled || this.isVisitRequestCanceled;
    }

    get canRate(): boolean {
        return this.isCliente &&
            (this.ticket?.estadoItem?.codigo === 'CERRADO' || this.ticket?.estadoItem?.codigo === 'RESUELTO') &&
            !this.ticket?.calificacionSatisfaccion;
    }

    get alreadyRated(): boolean {
        return !!this.ticket?.calificacionSatisfaccion;
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
                this.modalData.title = 'Marcar como Resuelto';
                this.modalData.confirmText = 'Ya apliqué la solución, por favor valida si funciona correctamente.';
                break;
            case 'REQUIERE_VISITA':
                this.modalData.title = 'Solicitar Visita Técnica';
                this.modalData.confirmText = 'Solicitar visita';
                break;
            case 'CERRADO':
                this.modalData.title = 'Cerrar Ticket (Verificado)';
                this.modalData.confirmText = 'Se validó que la solución funciona; el caso está terminado y archivado.';
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

    openReassignModal(): void {
        this.reassignData.userId = this.ticket.usuarioAsignado?.id || this.ticket.usuarioAsignado?.userId || 0;
        this.reassignData.notaReasignacion = '';
        this.reassignSearchTerm = '';
        this.selectedTechForPreview = null;
        
        // UX Fix: Open modal instantly
        this.showReassignModal = true;
        this.loadingTechnicians = true;
        
        // Load technicians for the list asynchronously
        this.ticketService.getDetailedTechnicians().subscribe({
            next: (data) => {
                this.technicians = data;
                this.loadingTechnicians = false;
                // Pre-select current if possible
                if (this.reassignData.userId) {
                    this.selectedTechForPreview = this.technicians.find(t => t.userId === this.reassignData.userId);
                }
                this.cdr.detectChanges();
            },
            error: (err) => {
                console.error('Error loading technicians', err);
                this.loadingTechnicians = false;
                this.cdr.detectChanges();
            }
        });
    }

    get filteredTechnicians(): any[] {
        if (!this.reassignSearchTerm) return this.technicians;
        const term = this.reassignSearchTerm.toLowerCase();
        return this.technicians.filter(t => 
            t.nombre?.toLowerCase().includes(term) || 
            t.apellido?.toLowerCase().includes(term) || 
            t.cedula?.includes(term) ||
            t.cargo?.toLowerCase().includes(term)
        );
    }

    selectTech(tech: any): void {
        this.reassignData.userId = tech.userId;
        this.selectedTechForPreview = tech;
    }

    onConfirmReassign(): void {
        if (!this.reassignData.userId || !this.reassignData.notaReasignacion.trim()) {
            alert('Por favor seleccione un técnico y escriba una nota de reasignación.');
            return;
        }

        const wasRequiresVisit = this.ticket.estadoItem?.codigo === 'REQUIERE_VISITA';

        this.showReassignModal = false;
        this.loading = true;
        this.cdr.detectChanges();

        this.ticketService.reassignTicket(
            this.ticket.idTicket,
            this.reassignData.userId,
            this.reassignData.notaReasignacion
        ).subscribe({
            next: () => {
                if (wasRequiresVisit) {
                    // Keep the ticket status in REQUIERE_VISITA when reassigning.
                    this.ticketService.updateStatus(this.ticket.idTicket, 'REQUIERE_VISITA', 'Reasignación de técnico manteniendo solicitud de visita.').subscribe({
                        next: () => {
                            this.zone.run(() => {
                                this.successMessage = 'Ticket reasignado manteniendo estado de visita.';
                                setTimeout(() => this.successMessage = '', 4000);
                                this.loadTicket(this.ticket.idTicket);
                                this.cdr.detectChanges();
                            });
                        },
                        error: () => {
                            // Even if status update fails, refresh ticket to avoid stale assignment state.
                            this.zone.run(() => {
                                this.loadTicket(this.ticket.idTicket);
                                this.cdr.detectChanges();
                            });
                        }
                    });
                } else {
                    this.zone.run(() => {
                        this.successMessage = 'Ticket reasignado exitosamente.';
                        setTimeout(() => this.successMessage = '', 4000);
                        this.loadTicket(this.ticket.idTicket);
                        this.cdr.detectChanges();
                    });
                }
            },
            error: (err) => {
                this.zone.run(() => {
                    this.error = err.error?.message || 'Error al reasignar el ticket.';
                    this.loading = false;
                    this.cdr.detectChanges();
                });
            }
        });
    }

    changeStatus(statusCode: string): void {
        this.openConfirmModal(statusCode);
    }

    getStatusBadgeClass(statusCode: string): string {
        switch (statusCode?.toUpperCase()) {
            case 'ABIERTO': return 'bg-info-subtle text-info';
            case 'ASIGNADO': return 'bg-primary-subtle text-primary';
            case 'EN_PROCESO': return 'bg-warning-subtle text-warning';
            case 'RESUELTO': return 'bg-success-subtle text-success';
            case 'CERRADO': return 'bg-success-subtle text-success';
            case 'REQUIERE_VISITA': return 'bg-danger-subtle text-danger';
            case 'REPROGRAMADA': return 'bg-dark-subtle text-dark';
            default: return 'bg-secondary-subtle text-secondary';
        }
    }

    // ─── Tech Work Form helpers ────────────────────────────────────────────────

    /** Whether the tech work form panel should be shown */
    get showTechWorkForm(): boolean {
        // Point 4: Admin is not a technician. Admin must not see tech form.
        if (this.isOnlyTecnico || this.isAdminMaster) {
             // Only actual technician (or Master if acting as one) can see it in EN_PROCESO
             if (this.isAdminMaster && !this.isAssignedToMe) return false;
             
             const status = this.ticket?.estadoItem?.codigo;
             return status === 'EN_PROCESO' && this.isAssignedToMe;
        }
        return false;
    }

    /** Whether to show the existing informe summary (read-only) */
    get showInformeSummary(): boolean {
        // Show history if it exists, regardless of current state
        return this.historialInformes.length > 0;
    }

    isChipSelected(list: string[], value: string): boolean {
        return list.includes(value);
    }

    toggleChip(list: string[], value: string, category?: string): void {
        // Enforce logic: NO_APLICA deselects everything else
        if (value === 'NO_APLICA') {
            list.length = 0;
            list.push(value);
            return;
        }

        // If something else is selected and NO_APLICA was there, remove NO_APLICA
        const noAplicaIdx = list.indexOf('NO_APLICA');
        if (noAplicaIdx > -1) {
            list.splice(noAplicaIdx, 1);
        }

        const index = list.indexOf(value);
        if (index > -1) {
            list.splice(index, 1);
        } else {
            list.push(value);
        }
    }

    submitTechForm() {
        if (!this.confirmStage2()) return;

        this.techFormSubmitting = true;
        this.techFormError = '';

        const payload = {
            resultado: this.techFormTab,
            implementosUsados: this.selectedImplementos.join(', '),
            problemasEncontrados: this.selectedProblemas.join(', '),
            solucionAplicada: this.selectedSoluciones.join(', '),
            pruebasRealizadas: this.selectedPruebas.join(', '),
            motivoNoResolucion: this.techFormTab === 'NO_RESUELTO' ? this.selectedMotivo : null,
            comentarioTecnico: this.comentarioTecnico,
            tiempoTrabajoMinutos: this.tiempoTrabajo,
            inventarioItems: this.selectedInventario.map(item => ({
                idItemInventario: item.idItemInventario,
                cantidad: item.cantidad
            }))
        };
        this.ticketService.submitInforme(this.ticket.idTicket, payload).subscribe({
            next: (res: any) => {
                this.techFormSubmitting = false;
                this.techFormSuccess = true;
                this.informeTecnico = res;
                this.resetTechForm();
                this.loadTicket(this.ticket.idTicket);
            },
            error: (err: any) => {
                this.techFormSubmitting = false;
                this.techFormError = err.error?.message || 'Error al guardar el informe';
            }
        });
    }

    confirmStage1() {
        if (this.selectedProblemas.length === 0) {
            this.techFormError = 'Debe seleccionar al menos un problema encontrado.';
            return;
        }
        if (this.selectedSoluciones.length === 0) {
            this.techFormError = 'Debe seleccionar la solución aplicada.';
            return;
        }
        if (this.selectedPruebas.length === 0) {
            this.techFormError = 'Debe registrar al menos una prueba realizada.';
            return;
        }
        this.techFormError = '';
        this.formStep = 2;
    }

    confirmStage2() {
        if (this.techFormTab === 'NO_RESUELTO' && !this.selectedMotivo) {
            this.techFormError = 'Por favor, seleccione el motivo de no resolución.';
            return false;
        }
        return true;
    }

    // ─── Search and Filtering ──────────────────────────────────────────────────

    filteredImplementosList: string[] = [];
    filteredProblemasList: string[] = [];
    filteredSolucionesList: string[] = [];
    filteredPruebasList: string[] = [];

    get filteredImplementos() { return this.filteredImplementosList; }
    get filteredProblemas() { return this.filteredProblemasList; }
    get filteredSoluciones() { return this.filteredSolucionesList; }
    get filteredPruebas() { return this.filteredPruebasList; }
    get filteredInventory() { return this.filteredInventoryList; }

    onSearchTermChange() {
        // Debounce not needed for small memory arrays, but could be added
        this.updateGeneralFilters();
    }

    onInventorySearchChange() {
        this.updateInventoryFilter();
    }

    updateGeneralFilters() {
        this.filteredImplementosList = this.filterList(this.implementosOpciones, 'implementos');
        this.filteredProblemasList = this.filterList(this.problemasOpciones, 'problemas');
        this.filteredSolucionesList = this.filterList(this.solucionesOpciones, 'soluciones');
        this.filteredPruebasList = this.filterList(this.pruebasOpciones, 'pruebas');
    }

    updateInventoryFilter() {
        if (!this.inventorySearchTerm) {
            this.filteredInventoryList = this.availableInventario;
            return;
        }
        const term = this.inventorySearchTerm.toLowerCase();
        this.filteredInventoryList = this.availableInventario.filter(item =>
            item.nombre?.toLowerCase().includes(term) ||
            item.codigo?.toLowerCase().includes(term)
        );
    }

    private filterList(list: string[], category: string) {
        if (this.searchCategory && this.searchCategory !== category) return [];
        if (!this.searchTerm) return list;
        const term = this.searchTerm.toLowerCase();
        return list.filter(opt => opt.toLowerCase().includes(term));
    }

    setSearchCategory(cat: string) {
        this.searchCategory = (this.searchCategory === cat) ? '' : cat;
        this.updateGeneralFilters();
    }

    // ─── Dynamic Coloring ──────────────────────────────────────────────────────

    getChipColorClass(category: string, value: string) {
        if (value === 'NO_APLICA') return 'chip-no-aplica';
        if (value === 'SIN_MATERIAL') return 'chip-sin-material';

        if (!this.frecuencias || !this.frecuencias[category]) return 'freq-low';

        const count = this.frecuencias[category][value] || 0;
        if (count > 5) return 'freq-high';
        if (count > 2) return 'freq-medium';
        return 'freq-low';
    }

    // ─── Inventory management ──────────────────────────────────────────────────

    toggleInventario(item: any) {
        const idx = this.selectedInventario.findIndex(i => i.idItemInventario === item.idItemInventario);
        if (idx >= 0) {
            this.selectedInventario.splice(idx, 1);
        } else {
            if (!item.cantidad) item.cantidad = 1;
            this.selectedInventario.push(item); // Push same reference to share quantity
        }
    }

    isInventarioSelected(item: any) {
        return this.selectedInventario.some(i => i.idItemInventario === item.idItemInventario);
    }

    // ─── PDF Export ────────────────────────────────────────────────────────────

    downloadPdf() {
        this.ticketService.downloadPdf(this.ticket.idTicket).subscribe({
            next: (blob) => {
                const url = window.URL.createObjectURL(blob);
                const a = document.createElement('a');
                a.href = url;
                a.download = `Ticket_${this.ticket.idTicket}_Reporte.pdf`;
                a.click();
                window.URL.revokeObjectURL(url);
            },
            error: (err) => {
                console.error('Error downloading PDF', err);
                alert('No se pudo generar el PDF en este momento.');
            }
        });
    }

    /** Parse comma-separated string into array for display */
    listFromText(text: string | null): string[] {
        if (!text) return [];
        return text.split(',').map(s => s.trim()).filter(s => !!s);
    }

    // ─── Timer Logic (Work Time Counter) ───────────────────────────────────────

    private handleTimerLogic(): void {
        if (this.ticket?.estadoItem?.codigo === 'EN_PROCESO') {
            this.startTimer();
        } else {
            this.stopTimer();
            // If already resolved, maybe show the final time from informe but keep default for form
            if (this.informeTecnico?.tiempoTrabajoMinutos) {
                this.tiempoTrabajo = this.informeTecnico.tiempoTrabajoMinutos;
            }
        }
    }

    private startTimer(): void {
        this.stopTimer(); // Clear existing
        
        // Find when it entered EN_PROCESO state
        const history = this.ticket?.historialEstados || [];
        const lastInProcess = [...history].reverse().find((h: any) => h.estadoNuevo?.codigo === 'EN_PROCESO');
        
        if (!lastInProcess) return;

        const startTime = new Date(lastInProcess.fechaCambio).getTime();
        
        this.timerInterval = setInterval(() => {
            const now = new Date().getTime();
            const diff = now - startTime;
            
            const hours = Math.floor(diff / (1000 * 60 * 60));
            const minutes = Math.floor((diff % (1000 * 60 * 60)) / (1000 * 60));
            const seconds = Math.floor((diff % (1000 * 60)) / 1000);
            
            this.elapsedTimeDisplay = 
                (hours < 10 ? '0' + hours : hours) + ':' + 
                (minutes < 10 ? '0' + minutes : minutes) + ':' + 
                (seconds < 10 ? '0' + seconds : seconds);
            
            // Auto-calculate the minutes for the submission form
            this.tiempoTrabajo = Math.max(1, Math.round(diff / (1000 * 60)));
            this.cdr.detectChanges();
        }, 1000);
    }

    private stopTimer(): void {
        if (this.timerInterval) {
            clearInterval(this.timerInterval);
            this.timerInterval = null;
        }
    }

    private resetTechForm(): void {
        this.formStep = 1;
        this.selectedImplementos = [];
        this.selectedProblemas = [];
        this.selectedSoluciones = [];
        this.selectedPruebas = [];
        this.selectedMotivo = '';
        this.comentarioTecnico = '';
        this.selectedInventario = [];
        this.techFormTab = 'RESUELTO';
        this.techFormError = '';
        this.techFormSuccess = false;
    }

    isMe(comment: any): boolean {
        if (!this.currentUser || !comment.usuario) return false;
        return comment.usuario.id === this.currentUser.id || 
               comment.usuario.username === this.currentUser.username;
    }

    getInitials(user: any): string {
        if (!user) return 'U';
        const name = user.nombre || user.persona?.nombre || '';
        const lastName = user.apellido || user.persona?.apellido || '';
        if (name && lastName) return (name.substring(0, 1) + lastName.substring(0, 1)).toUpperCase();
        const username = user.username || '';
        if (username.length >= 2) return username.substring(0, 2).toUpperCase();
        return username.substring(0, 1).toUpperCase() || 'U';
    }
}
