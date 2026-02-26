import { Component, OnInit, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { TicketService } from '../../_services/ticket.service';
import { UserService } from '../../_services/user.service';
import { Ticket } from '../../models/ticket';
import { UserAdminView } from '../../models/user-admin-view.model';
import { FormsModule } from '@angular/forms';
import { RouterModule } from '@angular/router';

@Component({
    selector: 'app-ticket-assignment',
    standalone: true,
    imports: [CommonModule, FormsModule, RouterModule],
    templateUrl: './ticket-assignment.component.html',
    styleUrls: ['./ticket-assignment.component.css']
})
export class TicketAssignmentComponent implements OnInit {
    tickets: Ticket[] = [];
    technicians: UserAdminView[] = [];
    loading = true;
    error = '';
    success = '';

    constructor(
        private ticketService: TicketService,
        private userService: UserService,
        private cdr: ChangeDetectorRef
    ) { }

    ngOnInit(): void {
        this.loadData();
    }

    loadData(): void {
        this.loading = true;
        this.error = '';

        this.ticketService.getAllTickets().subscribe({
            next: (data) => {
                this.tickets = data.map(t => ({
                    ...t,
                    idUsuarioAsignado: t.idUsuarioAsignado || t.usuarioAsignado?.id
                }));
                this.loadTechnicians();
            },
            error: (err) => {
                this.error = 'No se pudieron cargar los tickets.';
                this.loading = false;
                this.cdr.detectChanges();
            }
        });
    }

    loadTechnicians(): void {
        this.userService.getAllUsers('TECNICO').subscribe({
            next: (data) => {
                this.technicians = data;
                this.loading = false;
                this.cdr.detectChanges();
            },
            error: (err) => {
                this.error = 'No se pudieron cargar los técnicos.';
                this.loading = false;
                this.cdr.detectChanges();
            }
        });
    }

    assignTicket(ticketId: number, event: any): void {
        const userId = +event.target.value;
        if (!userId) return;

        this.ticketService.assignTicket(ticketId, userId).subscribe({
            next: () => {
                this.success = `Ticket #${ticketId} asignado correctamente.`;
                setTimeout(() => this.success = '', 3000);
                this.loadData();
            },
            error: (err) => {
                this.error = 'Error al asignar el ticket.';
            }
        });
    }

    getStatusBadgeClass(status: string): string {
        switch (status?.toUpperCase()) {
            case 'ABIERTO': return 'bg-danger-subtle text-danger';
            case 'ASIGNADO': return 'bg-primary-subtle text-primary';
            case 'EN_PROCESO': return 'bg-warning-subtle text-warning';
            case 'RESUELTO': return 'bg-success-subtle text-success';
            default: return 'bg-secondary-subtle text-secondary';
        }
    }
}
