import { Component, OnInit, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { TicketService } from '../../_services/ticket.service';
import { TokenStorageService } from '../../_services/token-storage.service';

@Component({
  selector: 'app-tech-performance',
  templateUrl: './tech-performance.component.html',
  styleUrls: ['./tech-performance.component.css'],
  standalone: true,
  imports: [CommonModule, RouterModule]
})
export class TechPerformanceComponent implements OnInit {
  isLoading = true;
  currentUser: any = null;

  performance = {
    avgRating: 0,
    totalEvaluations: 0,
    totalTickets: 0,
    resolvedTickets: 0,
    responseTimeRating: 4.8,
    qualityRating: 4.7,
    courtesyRating: 4.9,
    recentFeedback: [] as any[]
  };

  constructor(
    private ticketService: TicketService,
    private tokenStorage: TokenStorageService,
    private cdr: ChangeDetectorRef
  ) { }

  ngOnInit(): void {
    this.currentUser = this.tokenStorage.getUser();
    this.loadPerformanceData();
  }

  loadPerformanceData(): void {
    if (!this.currentUser || !this.currentUser.id) return;
    this.isLoading = true;

    // Fetch general stats
    this.ticketService.getTechnicianStats(this.currentUser.id).subscribe({
      next: (stats) => {
        this.performance.avgRating = stats.promedio || 0;
        this.performance.totalEvaluations = stats.totalCalificados || 0;
        this.performance.totalTickets = stats.totalTickets || 0;
        
        // Mocks for specific metrics (simulated from overall avg)
        this.performance.responseTimeRating = Number((this.performance.avgRating * 0.96).toFixed(1));
        this.performance.qualityRating = Number((this.performance.avgRating * 1.02).toFixed(1));
        this.performance.courtesyRating = Number((this.performance.avgRating * 0.98).toFixed(1));
        
        this.cdr.detectChanges();
      }
    });

    // Fetch specific tickets to get comments
    this.ticketService.getAssignedTickets().subscribe({
      next: (tickets) => {
        this.performance.resolvedTickets = tickets.filter(t => t.estadoItem?.codigo === 'RESUELTO').length;
        
        this.performance.recentFeedback = tickets
          .filter(t => t.calificacionSatisfaccion && t.comentarioCalificacion)
          .sort((a, b) => new Date(b.fechaCierre!).getTime() - new Date(a.fechaCierre!).getTime())
          .slice(0, 5) // Show top 5
          .map(t => ({
            id: t.idTicket,
            subject: t.asunto,
            rating: t.calificacionSatisfaccion,
            comment: t.comentarioCalificacion,
            date: t.fechaCierre,
            client: (t.cliente?.persona?.nombre || 'U') + ' ' + (t.cliente?.persona?.apellido || '')
          }));
        
        this.isLoading = false;
        this.cdr.detectChanges();
      },
      error: () => {
        this.isLoading = false;
        this.cdr.detectChanges();
      }
    });
  }
}
