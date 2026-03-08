import { Component, OnInit, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { TicketService } from '../../_services/ticket.service';
import { UserService } from '../../_services/user.service';
import { CompanyService } from '../../_services/company.service';
import { Ticket } from '../../models/ticket';
import { UserAdminView } from '../../models/user-admin-view.model';
import { FormsModule } from '@angular/forms';
import { RouterModule } from '@angular/router';
import { forkJoin, of } from 'rxjs';
import { catchError } from 'rxjs/operators';

@Component({
    selector: 'app-ticket-assignment',
    standalone: true,
    imports: [CommonModule, FormsModule, RouterModule],
    templateUrl: './ticket-assignment.component.html',
    styleUrls: ['./ticket-assignment.component.css']
})
export class TicketAssignmentComponent implements OnInit {
    allTickets: Ticket[] = [];
    filteredTickets: Ticket[] = [];
    technicians: UserAdminView[] = [];
    companiesMap: Map<number, string> = new Map();

    // Filters & Metadata
    searchTerm = '';
    statusFilter = 'TODOS';
    loading = true;
    error = '';
    success = '';

    // Pagination
    currentPage = 1;
    pageSize = 6;
    totalPages = 1;
    paginatedTickets: Ticket[] = [];

    // Operations Hub Metrics
    stats = {
        unassigned: 0,
        critical: 0,
        inProgress: 0,
        techsAvailable: 0
    };

    constructor(
        private ticketService: TicketService,
        private userService: UserService,
        private companyService: CompanyService,
        private cdr: ChangeDetectorRef
    ) { }

    ngOnInit(): void {
        this.loadData();
    }

    loadData(): void {
        this.loading = true;
        this.error = '';

        forkJoin({
            tickets: this.ticketService.getAllTickets().pipe(catchError(() => of([]))),
            techs: this.userService.getAllUsers('TECNICO').pipe(catchError(() => of([]))),
            companies: this.companyService.getISPs().pipe(catchError(() => of([])))
        }).subscribe({
            next: (res) => {
                // Map companies
                res.companies.forEach(c => this.companiesMap.set(c.id, c.nombreComercial));

                this.allTickets = res.tickets.map(t => ({
                    ...t,
                    idUsuarioAsignado: t.idUsuarioAsignado || t.usuarioAsignado?.id,
                    idEmpresa: t.idEmpresa || t.sucursal?.idEmpresa
                }));

                this.technicians = res.techs;
                this.calculateStats();
                this.applyFilters();

                this.loading = false;
                this.cdr.detectChanges();
            },
            error: (err) => {
                this.error = 'Error de sincronización con el servidor.';
                this.loading = false;
                this.cdr.detectChanges();
            }
        });
    }

    calculateStats(): void {
        this.stats.unassigned = this.allTickets.filter(t => !t.idUsuarioAsignado).length;
        this.stats.critical = this.allTickets.filter(t => t.prioridadItem?.codigo === 'URGENTE' || t.prioridadItem?.nombre === 'Alta' || t.idPrioridadItem === 3).length;
        this.stats.inProgress = this.allTickets.filter(t => t.estadoItem?.codigo === 'EN_PROCESO').length;
        this.stats.techsAvailable = this.technicians.filter(u => u.estado === 'ACTIVO').length;
    }

    applyFilters(): void {
        let docs = [...this.allTickets];

        // Status Filter
        if (this.statusFilter !== 'TODOS') {
            if (this.statusFilter === 'SIN_ASIGNAR') {
                docs = docs.filter(t => !t.idUsuarioAsignado);
            } else {
                docs = docs.filter(t => t.estadoItem?.codigo === this.statusFilter);
            }
        }

        // Search Term
        if (this.searchTerm) {
            const term = this.searchTerm.toLowerCase();
            docs = docs.filter(t =>
                t.asunto?.toLowerCase().includes(term) ||
                t.idTicket?.toString().includes(term) ||
                t.cliente?.persona?.nombre?.toLowerCase().includes(term) ||
                t.cliente?.persona?.apellido?.toLowerCase().includes(term) ||
                this.getCompanyName(t.idEmpresa).toLowerCase().includes(term)
            );
        }

        // Sort: Priority first, then Newest
        this.filteredTickets = docs.sort((a, b) => {
            const prioA = this.getPriorityWeight(a.prioridadItem?.codigo || '');
            const prioB = this.getPriorityWeight(b.prioridadItem?.codigo || '');
            if (prioA !== prioB) return prioB - prioA;
            return (b.idTicket || 0) - (a.idTicket || 0);
        });

        // Reset to first page when filtering
        this.currentPage = 1;
        this.updatePagination();
    }

    updatePagination(): void {
        this.totalPages = Math.ceil(this.filteredTickets.length / this.pageSize);
        const startIndex = (this.currentPage - 1) * this.pageSize;
        this.paginatedTickets = this.filteredTickets.slice(startIndex, startIndex + this.pageSize);
    }

    changePage(page: number): void {
        if (page >= 1 && page <= this.totalPages) {
            this.currentPage = page;
            this.updatePagination();
            window.scrollTo({ top: 0, behavior: 'smooth' });
        }
    }

    private getPriorityWeight(code: string): number {
        if (code === 'URGENTE' || code === 'CRITICA') return 4;
        if (code === 'ALTA') return 3;
        if (code === 'MEDIA') return 2;
        return 1;
    }

    getCompanyName(id: number | undefined): string {
        if (id === undefined) return 'Empresa Interna';
        return this.companiesMap.get(id) || 'Empresa Interna';
    }

    getTechLoad(techId: number): number {
        return this.allTickets.filter(t => t.idUsuarioAsignado === techId && t.estadoItem?.codigo !== 'CERRADO' && t.estadoItem?.codigo !== 'RESUELTO').length;
    }

    assignTicket(ticket: Ticket): void {
        const userId = ticket.idUsuarioAsignado;
        if (!userId) return;

        this.ticketService.assignTicket(ticket.idTicket!, userId).subscribe({
            next: () => {
                this.success = `¡Ticket #${ticket.idTicket} despachado exitosamente!`;
                setTimeout(() => this.success = '', 3000);
                this.loadData();
            },
            error: (err) => {
                this.error = 'No se pudo completar la asignación.';
            }
        });
    }

    getPriorityClass(priority?: string): string {
        switch (priority?.toUpperCase()) {
            case 'URGENTE':
            case 'CRITICA':
            case 'ALTA': return 'border-priority-high';
            case 'MEDIA': return 'border-priority-medium';
            case 'BAJA': return 'border-priority-low';
            default: return 'border-priority-none';
        }
    }

    getStatusBadgeClass(status?: string): string {
        switch (status?.toUpperCase()) {
            case 'ABIERTO': return 'badge-status-open';
            case 'ASIGNADO': return 'badge-status-assigned';
            case 'EN_PROCESO': return 'badge-status-progress';
            case 'RESUELTO': return 'badge-status-resolved';
            default: return 'badge-status-default';
        }
    }
}
