import { Component, OnInit, ChangeDetectorRef, NgZone } from '@angular/core';
import { CommonModule, NgClass } from '@angular/common';
import { Ticket } from '../../models/ticket';
import { TicketService } from '../../_services/ticket.service';
import { RouterModule } from '@angular/router';
import { FormsModule } from '@angular/forms';

interface StatusInfo {
  text: string;
  cssClass: string;
}

@Component({
  selector: 'app-board-technician',
  templateUrl: './board-technician.component.html',
  styleUrls: ['./board-technician.component.css'],
  standalone: true,
  imports: [CommonModule, NgClass, RouterModule, FormsModule]
})
export class BoardTechnicianComponent implements OnInit {
  tickets: Ticket[] = [];
  allTickets: Ticket[] = [];
  filteredTickets: Ticket[] = [];
  errorMessage: string = '';
  isLoading: boolean = true;
  statusFilter: string = 'ASIGNADOS';
  searchTerm: string = '';
  
  stats = {
    totalAsignadas: 0,
    enProgreso: 0,
    resueltas: 0,
    requiereVisita: 0
  };

  // Status mapping using codes from database
  private statusMap: { [key: string]: StatusInfo } = {
    'ABIERTO': { text: 'Abierto', cssClass: 'status-abierto' },
    'ASIGNADO': { text: 'Asignado', cssClass: 'status-asignado' },
    'EN_PROCESO': { text: 'En Progreso', cssClass: 'status-proceso' },
    'RESUELTO': { text: 'Resuelto', cssClass: 'status-resuelto' },
    'CERRADO': { text: 'Cerrado', cssClass: 'status-cerrado' },
    'RECHAZADO': { text: 'Rechazado', cssClass: 'status-rechazado' },
    'REQUIERE_VISITA': { text: 'Requiere Visita', cssClass: 'status-visita' },
    'REPROGRAMADA': { text: 'Reprogramada', cssClass: 'status-reprogramada' }
  };

  constructor(
    private ticketService: TicketService,
    private cdr: ChangeDetectorRef,
    private zone: NgZone
  ) { }

  ngOnInit(): void {
    this.loadTickets();
  }

  updateStats(): void {
    if (!this.allTickets) return;
    
    // Total Asignadas = Strictly currently assigned (Points 3 & 5) + REQUIERE_VISITA (ITSM flow)
    this.stats.totalAsignadas = this.allTickets.filter(t => 
        t.estadoItem?.codigo === 'ASIGNADO' || t.estadoItem?.codigo === 'REQUIERE_VISITA'
    ).length;
    
    this.stats.enProgreso = this.allTickets.filter(t => t.estadoItem?.codigo === 'EN_PROCESO').length;
    
    // Point: Count current state RESUELTO and CERRADO
    this.stats.resueltas = this.allTickets.filter(t => 
      t.estadoItem?.codigo === 'RESUELTO' || t.estadoItem?.codigo === 'CERRADO'
    ).length;
    
    // Point: Strictly count tickets with REQUIERE_VISITA status
    this.stats.requiereVisita = this.allTickets.filter(t => t.estadoItem?.codigo === 'REQUIERE_VISITA').length;
  }

  loadTickets(): void {
    console.log('Iniciando carga de tickets asignados...');
    this.isLoading = true;
    this.errorMessage = '';
    this.cdr.detectChanges();

    this.ticketService.getAssignedTickets().subscribe({
      next: (data: Ticket[]) => {
        this.zone.run(() => {
          // Ensure unique tickets by ID to avoid double counting
          const seen = new Set();
          this.allTickets = data.filter(t => {
            if (seen.has(t.idTicket)) return false;
            seen.add(t.idTicket);
            return true;
          });
          
          this.updateStats(); // Calculate stats once from ALL data
          this.isLoading = false;
          this.applyFilters();
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
      }
    });
  }

  applyFilters(): void {
    let docs = [...this.allTickets];

    // Status Filter
    switch (this.statusFilter) {
      case 'ASIGNADOS':
        docs = docs.filter(t => t.estadoItem?.codigo === 'ASIGNADO' || t.estadoItem?.codigo === 'REQUIERE_VISITA');
        break;
      case 'EN_PROCESO':
        docs = docs.filter(t => t.estadoItem?.codigo === 'EN_PROCESO');
        break;
      case 'CERRADOS':
        // User want to see both resolved and closed here to match the 11 in stats
        docs = docs.filter(t => t.estadoItem?.codigo === 'CERRADO' || t.estadoItem?.codigo === 'RESUELTO');
        break;
      case 'REASIGNADOS':
        docs = docs.filter(t => {
          const isReprogramada = t.estadoItem?.codigo === 'REPROGRAMADA';
          const history = t.historialEstados || [];
          const assignmentCount = history.filter(h => h.estado?.codigo === 'ASIGNADO').length;
          // Point 2: REPROGRAMADA or been assigned more than once
          return isReprogramada || assignmentCount > 1;
        });
        break;
    }

    // Search Term
    if (this.searchTerm) {
      const term = this.searchTerm.toLowerCase();
      docs = docs.filter(t =>
        t.asunto?.toLowerCase().includes(term) ||
        t.idTicket?.toString().includes(term)
      );
    }

    // Sort: REPROGRAMADA first, then by ID descending
    this.tickets = docs.sort((a, b) => {
      if (a.estadoItem?.codigo === 'REPROGRAMADA' && b.estadoItem?.codigo !== 'REPROGRAMADA') return -1;
      if (a.estadoItem?.codigo !== 'REPROGRAMADA' && b.estadoItem?.codigo === 'REPROGRAMADA') return 1;
      return (b.idTicket || 0) - (a.idTicket || 0);
    });
  }

  getStatusInfo(status: string | undefined): StatusInfo {
    const code = status?.toUpperCase() || 'UNKNOWN';
    return this.statusMap[code] || { text: `Desconocido (${code})`, cssClass: 'status-unknown' };
  }
}
