import { Component, OnInit, ChangeDetectorRef, NgZone, ViewChild, ElementRef, AfterViewChecked } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ActivatedRoute, RouterModule } from '@angular/router';
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
    informeTecnico: any = null;
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

    constructor(
        private route: ActivatedRoute,
        private ticketService: TicketService,
        private visitaService: VisitaService,
        private tokenService: TokenStorageService,
        private masterDataService: MasterDataService,
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
                    this.loading = false;
                    // checkPermissions already called in ngOnInit, but update just in case roles come from data
                    this.loadInformeTecnico(id);
                    this.calculateUnreadMessages(id);
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

    loadInformeTecnico(ticketId: number): void {
        if (!this.isTecnico && !this.showStatusUpdate) return;
        this.loadingInforme = true;

        // Load main informe
        this.ticketService.getInforme(ticketId).subscribe({
            next: (informe) => {
                this.zone.run(() => {
                    this.informeTecnico = informe;
                    this.loadingInforme = false;
                    this.cdr.detectChanges();
                });
            },
            error: (err) => {
                this.zone.run(() => {
                    this.informeTecnico = null;
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

            this.isTecnico = roles.includes('ROLE_TECNICO') || roles.includes('ROLE_ADMIN_MASTER');
            this.isOnlyTecnico = roles.includes('ROLE_TECNICO') && !roles.includes('ROLE_ADMIN_MASTER') && !roles.includes('ROLE_ADMIN');

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
            case 'REPROGRAMADA':
                this.modalData.title = 'Reprogramar Incidencia';
                this.modalData.confirmText = 'Reprogramar ticket';
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
        return this.isTecnico && this.ticket?.estadoItem?.codigo === 'EN_PROCESO';
    }

    /** Whether to show the existing informe summary (read-only) */
    get showInformeSummary(): boolean {
        return this.isTecnico && !!this.informeTecnico;
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
            next: (res) => {
                this.techFormSubmitting = false;
                this.techFormSuccess = true;
                this.informeTecnico = res;
                this.loadTicket(this.ticket.idTicket);
            },
            error: (err) => {
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
}
