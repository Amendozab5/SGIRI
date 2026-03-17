import { Component, OnInit, ViewChild, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ActivatedRoute } from '@angular/router';
import { FormsModule } from '@angular/forms';
import { VisitaService } from '../../_services/visita.service';
import { TicketService } from '../../_services/ticket.service';
import { UserService } from '../../_services/user.service';
import { VisitaTecnica, VisitaRequest } from '../../models/visita';
import { Ticket } from '../../models/ticket';
import { UserAdminView } from '../../models/user-admin-view.model';
import { VisitaFormModalComponent } from '../visita-form-modal/visita-form-modal.component';
import { CdkDragDrop, DragDropModule } from '@angular/cdk/drag-drop';
import { TokenStorageService } from '../../_services/token-storage.service';

interface DayCell {
    date: Date;
    isCurrentMonth: boolean;
    isToday: boolean;
    isPast: boolean;
    visitas: VisitaTecnica[];
}

@Component({
    selector: 'app-scheduler',
    templateUrl: './scheduler.component.html',
    styleUrls: ['./scheduler.component.css'],
    standalone: true,
    imports: [CommonModule, VisitaFormModalComponent, FormsModule, DragDropModule]
})
export class SchedulerComponent implements OnInit {
    currentDate = new Date();
    days: DayCell[] = [];
    weekDays = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];

    tickets: Ticket[] = [];
    tecnicos: UserAdminView[] = [];
    allVisitas: VisitaTecnica[] = [];
    selectedTecnicoFilter: string = '';
    pendingSearchTerm: string = '';
    isUserTechnician: boolean = false;
    currentUsername: string = '';

    @ViewChild(VisitaFormModalComponent) visitaFormModal!: VisitaFormModalComponent;

    constructor(
        private visitaService: VisitaService,
        private ticketService: TicketService,
        private userService: UserService,
        private tokenService: TokenStorageService,
        private route: ActivatedRoute,
        private cdr: ChangeDetectorRef // Inyectar ChangeDetectorRef
    ) { }

    ngOnInit(): void {
        const user = this.tokenService.getUser();
        if (user) {
            this.currentUsername = user.username;
            this.isUserTechnician = user.roles.includes('ROLE_TECNICO');
            if (this.isUserTechnician) {
                this.selectedTecnicoFilter = this.currentUsername;
            }
        }
        this.generateCalendar();
        this.loadInitialData();
    }

    loadInitialData(): void {
        if (!this.isUserTechnician) {
            // Cargar tickets que REQUIEREN VISITA y NO tienen agenda ya colocada
            this.ticketService.getTicketsPendingVisit().subscribe(res => {
                this.tickets = res;
                this.cdr.detectChanges(); // Trigger change detection
                
                // Check for ticketId in query params to open modal directly
                this.route.queryParams.subscribe(params => {
                    const ticketId = params['ticketId'];
                    if (ticketId) {
                        const ticketToOpen = this.tickets.find(t => t.idTicket === +ticketId);
                        if (ticketToOpen) {
                            this.onPendingTicketClick(ticketToOpen);
                        } else {
                            // SI el ticket no está en pendientes (ej: viene de detalle sin ser REQUIERE_VISITA aún)
                            // lo cargamos directamente para poder agendarlo.
                             this.ticketService.getTicketById(+ticketId).subscribe(t => {
                                 if (t) {
                                     this.onPendingTicketClick(t);
                                 }
                             });
                        }
                    }
                });
            });

            // Cargar técnicos (incluyendo todos los roles operativos de empleados)
            this.userService.getAllUsers().subscribe(res => {
                const employeeRoles = ['TECNICO', 'ADMIN_TECNICOS', 'ADMIN_MASTER', 'ADMIN_CONTRATOS'];
                this.tecnicos = res.filter(u => u.roles.some(r => employeeRoles.includes(r.replace('ROLE_', ''))));
                this.cdr.detectChanges(); // Trigger change detection
            });
        }
    }

    generateCalendar(): void {
        const year = this.currentDate.getFullYear();
        const month = this.currentDate.getMonth();

        const firstDayOfMonth = new Date(year, month, 1);
        const lastDayOfMonth = new Date(year, month + 1, 0);

        // Get start of week for first day (ISO: Mon=1, Sun=0 adapt to Mon=0)
        let startDay = firstDayOfMonth.getDay();
        startDay = startDay === 0 ? 6 : startDay - 1;

        const startDate = new Date(firstDayOfMonth);
        startDate.setDate(startDate.getDate() - startDay);

        const newDays: DayCell[] = [];
        const calendarStart = new Date(startDate);
        const today = new Date();
        today.setHours(0, 0, 0, 0);

        // Generate 42 days (6 weeks)
        for (let i = 0; i < 42; i++) {
            const d = new Date(calendarStart);
            d.setDate(d.getDate() + i);

            const cellDate = new Date(d);
            cellDate.setHours(0, 0, 0, 0);

            newDays.push({
                date: d,
                isCurrentMonth: d.getMonth() === month,
                isToday: d.toDateString() === new Date().toDateString(),
                isPast: cellDate < today,
                visitas: []
            });
        }

        this.days = newDays;
        this.loadVisitas();
    }

    loadVisitas(): void {
        const start = this.formatDate(this.days[0].date);
        const end = this.formatDate(this.days[this.days.length - 1].date);

        this.visitaService.getVisitas(start, end).subscribe(res => {
            this.allVisitas = res;
            this.applyFilters();
        });
    }

    onFilterChange(event: any): void {
        this.selectedTecnicoFilter = event.target.value;
        this.applyFilters();
    }

    applyFilters(): void {
        this.days.forEach(day => {
            const dateStr = this.formatDate(day.date);
            day.visitas = this.allVisitas.filter(v => {
                const sameDate = v.fechaVisita === dateStr;
                // Si es técnico, solo cargamos SUS visitas. Si es admin, usamos el filtro seleccionado.
                const filterValue = this.isUserTechnician ? this.currentUsername : this.selectedTecnicoFilter;
                const matchesTecnico = !filterValue || v.tecnico.username === filterValue;
                return sameDate && matchesTecnico;
            });
        });
        this.cdr.detectChanges();
    }

    formatDate(date: Date): string {
        const year = date.getFullYear();
        const month = String(date.getMonth() + 1).padStart(2, '0');
        const day = String(date.getDate()).padStart(2, '0');
        return `${year}-${month}-${day}`;
    }

    prevMonth(): void {
        this.currentDate = new Date(this.currentDate.getFullYear(), this.currentDate.getMonth() - 1, 1);
        this.generateCalendar();
    }

    nextMonth(): void {
        this.currentDate = new Date(this.currentDate.getFullYear(), this.currentDate.getMonth() + 1, 1);
        this.generateCalendar();
    }

    today(): void {
        this.currentDate = new Date();
        this.generateCalendar();
    }

    onDayClick(day: DayCell): void {
        if (day.isPast || this.isUserTechnician) return;
        this.visitaFormModal.open(undefined, this.formatDate(day.date));
    }

    onPendingTicketClick(ticket: Ticket): void {
        const today = new Date();
        const dateStr = this.formatDate(today);
        this.visitaFormModal.open(undefined, dateStr, ticket.idTicket);
    }

    // CDK Drag and Drop Handlers
    dropTicket(event: CdkDragDrop<any>, day: DayCell): void {
        if (day.isPast || this.isUserTechnician) return;

        const ticket = event.item.data as Ticket;
        if (ticket) {
            this.visitaFormModal.open(undefined, this.formatDate(day.date), ticket.idTicket);
        }
    }

    onVisitaClick(event: MouseEvent, visita: VisitaTecnica): void {
        event.stopPropagation();
        this.visitaFormModal.open(visita);
    }

    onSaveVisita({ request, id }: { request: VisitaRequest, id: number | null }): void {
        if (id) {
            this.visitaService.updateVisita(id, request).subscribe({
                next: () => {
                    this.loadVisitas();
                    this.loadInitialData(); // Reload pending list
                    this.visitaFormModal.hide();
                },
                error: (err) => {
                    alert('Error al actualizar la visita: ' + (err.error?.message || err.message));
                }
            });
        } else {
            // Optimistic UI: remove from pending list before calling APIs
            const originalTickets = [...this.tickets];
            this.tickets = this.tickets.filter(t => t.idTicket !== request.idTicket);
            
            this.visitaService.createVisita(request).subscribe({
                next: () => {
                    // Actualizar el estado del ticket para cumplir el flujo ITSM
                    this.ticketService.updateStatus(request.idTicket, 'REQUIERE_VISITA', 'Visita agendada oficialmente por el administrador.').subscribe({
                        next: () => {
                            this.loadVisitas();
                            this.loadInitialData(); // Refrescar lista definitiva desde el backend
                            this.visitaFormModal.hide();
                        },
                        error: () => {
                            // Si falla el estado, igual refrescamos la agenda
                            this.loadVisitas();
                            this.loadInitialData();
                            this.visitaFormModal.hide();
                        }
                    });
                },
                error: (err) => {
                    // Revert optimistic removal on error
                    this.tickets = originalTickets;
                    alert('Error al crear la visita: ' + (err.error?.message || err.message));
                }
            });
        }
    }

    getStatusColor(codigo: string): string {
        switch (codigo) {
            case 'PROGRAMADA': return '#0d6efd';
            case 'CONFIRMADA': return '#ffc107';
            case 'REPROGRAMADA': return '#6f42c1';
            case 'CANCELADA': return '#dc3545';
            case 'FINALIZADA': return '#198754';
            default: return '#6c757d';
        }
    }

    isVisitaLocked(v: VisitaTecnica): boolean {
        const ticketStatus = v.ticket.estadoItem?.codigo;
        return ['FINALIZADA', 'CANCELADA'].includes(v.estado.codigo) ||
            ['CERRADO', 'RESUELTO'].includes(ticketStatus || '');
    }

    getInitials(name: string): string {
        if (!name) return '??';
        const parts = name.split(' ');
        if (parts.length >= 2) {
            return (parts[0][0] + parts[1][0]).toUpperCase();
        }
        return name.substring(0, 2).toUpperCase();
    }

    getAvatarColor(name: string): string {
        let hash = 0;
        for (let i = 0; i < name.length; i++) {
            hash = name.charCodeAt(i) + ((hash << 5) - hash);
        }
        const h = hash % 360;
        return `hsl(${h}, 60%, 45%)`;
    }

    getTecnicoLoad(username: string): number {
        return this.allVisitas.filter(v => v.tecnico.username === username).length;
    }

    get filteredPendingTickets(): Ticket[] {
        if (!this.pendingSearchTerm) return this.tickets;
        const term = this.pendingSearchTerm.toLowerCase();
        return this.tickets.filter(t => {
            const idMatch = t.idTicket?.toString().includes(term) || false;
            const asuntoMatch = t.asunto?.toLowerCase().includes(term) || false;
            const clienteNombre = (t.cliente?.persona?.nombre || '') + ' ' + (t.cliente?.persona?.apellido || '');
            const clienteMatch = clienteNombre.toLowerCase().includes(term);
            return idMatch || asuntoMatch || clienteMatch;
        });
    }
}
