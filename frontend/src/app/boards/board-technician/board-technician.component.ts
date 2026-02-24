import { Component, OnInit, ChangeDetectorRef, NgZone } from '@angular/core';
import { CommonModule, NgClass } from '@angular/common';
import { Ticket } from '../../models/ticket';
import { TicketService } from '../../_services/ticket.service';
import { RouterModule } from '@angular/router';

interface StatusInfo {
  text: string;
  cssClass: string;
}

@Component({
  selector: 'app-board-technician',
  templateUrl: './board-technician.component.html',
  styleUrls: ['./board-technician.component.css'],
  standalone: true,
  imports: [CommonModule, NgClass, RouterModule]
})
export class BoardTechnicianComponent implements OnInit {
  tickets: Ticket[] = [];
  errorMessage: string = '';
  isLoading: boolean = true;

  // Status mapping using codes from database
  private statusMap: { [key: string]: StatusInfo } = {
    'ABIERTO': { text: 'Abierto', cssClass: 'bg-info-subtle text-info' },
    'ASIGNADO': { text: 'Asignado', cssClass: 'bg-primary-subtle text-primary' },
    'EN_PROCESO': { text: 'En Progreso', cssClass: 'bg-warning-subtle text-warning' },
    'RESUELTO': { text: 'Resuelto', cssClass: 'bg-success-subtle text-success' },
    'CERRADO': { text: 'Cerrado', cssClass: 'bg-secondary-subtle text-secondary' },
    'RECHAZADO': { text: 'Rechazado', cssClass: 'bg-danger-subtle text-danger' }
  };

  constructor(
    private ticketService: TicketService,
    private cdr: ChangeDetectorRef,
    private zone: NgZone
  ) { }

  ngOnInit(): void {
    this.loadTickets();
  }

  loadTickets(): void {
    console.log('Iniciando carga de tickets asignados...');
    this.isLoading = true;
    this.errorMessage = '';
    this.cdr.detectChanges();

    this.ticketService.getAssignedTickets().subscribe({
      next: (data: Ticket[]) => {
        this.zone.run(() => {
          console.log('Tickets recibidos:', data);
          this.tickets = data;
          this.isLoading = false;
          this.cdr.detectChanges();
        });
      },
      error: (err: any) => {
        this.zone.run(() => {
          console.error('Error al cargar tickets:', err);
          this.errorMessage = 'No se pudieron cargar tus tareas asignadas.';
          this.isLoading = false;
          this.cdr.detectChanges();
        });
      },
      complete: () => {
        this.zone.run(() => {
          console.log('Carga finalizada.');
          this.cdr.detectChanges();
        });
      }
    });
  }

  getStatusInfo(status: string | undefined): StatusInfo {
    const code = status?.toUpperCase() || 'UNKNOWN';
    return this.statusMap[code] || { text: `Desconocido (${code})`, cssClass: 'bg-light text-dark' };
  }
}
