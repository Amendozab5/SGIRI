import { Component, OnInit, ViewChild, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { VisitaService } from '../../_services/visita.service';
import { TicketService } from '../../_services/ticket.service';
import { UserService } from '../../_services/user.service';
import { VisitaTecnica, VisitaRequest } from '../../models/visita';
import { Ticket } from '../../models/ticket';
import { UserAdminView } from '../../models/user-admin-view.model';
import { VisitaFormModalComponent } from '../visita-form-modal/visita-form-modal.component';

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
    imports: [CommonModule, VisitaFormModalComponent]
})
export class SchedulerComponent implements OnInit {
    currentDate = new Date();
    days: DayCell[] = [];
    weekDays = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];

    tickets: Ticket[] = [];
    tecnicos: UserAdminView[] = [];
    allVisitas: VisitaTecnica[] = [];
    selectedTecnicoFilter: string = '';

    @ViewChild(VisitaFormModalComponent) visitaFormModal!: VisitaFormModalComponent;

    constructor(
        private visitaService: VisitaService,
        private ticketService: TicketService,
        private userService: UserService,
        private cdr: ChangeDetectorRef // Inyectar ChangeDetectorRef
    ) { }

    ngOnInit(): void {
        this.generateCalendar();
        this.loadInitialData();
    }

    loadInitialData(): void {
        // Cargar tickets que REQUIEREN VISITA para el modal
        this.ticketService.getAllTickets().subscribe(res => {
            this.tickets = res.filter(t => t.estadoItem?.codigo === 'REQUIERE_VISITA');
        });

        // Cargar técnicos (usando el código correcto 'ADMIN_TECNICOS' a pedido del usuario)
        this.userService.getAllUsers().subscribe(res => {
            this.tecnicos = res.filter(u => u.roles.includes('ADMIN_TECNICOS'));
        });
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
                const matchesTecnico = !this.selectedTecnicoFilter || v.tecnico.username === this.selectedTecnicoFilter;
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
        if (day.isPast) return;
        this.visitaFormModal.open(undefined, this.formatDate(day.date));
    }

    onVisitaClick(event: MouseEvent, visita: VisitaTecnica): void {
        event.stopPropagation();
        this.visitaFormModal.open(visita);
    }

    onSaveVisita({ request, id }: { request: VisitaRequest, id: number | null }): void {
        if (id) {
            this.visitaService.updateVisita(id, request).subscribe(() => {
                this.loadVisitas();
                this.visitaFormModal.hide();
            });
        } else {
            this.visitaService.createVisita(request).subscribe(() => {
                this.loadVisitas();
                this.visitaFormModal.hide();
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
}
