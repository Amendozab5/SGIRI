import { Component, OnInit, OnDestroy, ChangeDetectorRef, NgZone } from '@angular/core';
import { CommonModule } from '@angular/common';
import { SharedStateService } from '../../_services/shared-state.service';
import { TicketService } from '../../_services/ticket.service';
import { RouterModule } from '@angular/router';
import { Subscription } from 'rxjs';
import { User } from '../../models/user.model';

@Component({
  selector: 'app-board-user',
  templateUrl: './board-user.component.html',
  styleUrls: ['./board-user.component.css'],
  standalone: true,
  imports: [CommonModule, RouterModule]
})
export class BoardUserComponent implements OnInit, OnDestroy {
  username?: string;
  incidentStats: any = { open: 0, inProgress: 0, resolved: 0 };
  incidents: any[] = [];
  isLoadingIncidents = true;
  errorMessage = '';
  private userSubscription: Subscription | undefined;

  constructor(
    private sharedState: SharedStateService,
    private ticketService: TicketService,
    private cdr: ChangeDetectorRef,
    private zone: NgZone
  ) { }

  ngOnInit(): void {
    this.userSubscription = this.sharedState.currentUser$.subscribe((user: User | null) => {
      if (user) {
        this.username = user.username;
      }
    });

    this.loadIncidents();
  }

  loadIncidents(): void {
    this.isLoadingIncidents = true;
    this.cdr.detectChanges();
    this.ticketService.getMyTickets().subscribe({
      next: (data: any[]) => {
        this.zone.run(() => {
          this.incidents = data;
          this.calculateStats();
          this.isLoadingIncidents = false;
          this.cdr.detectChanges();
        });
      },
      error: (err: any) => {
        this.zone.run(() => {
          console.error(err);
          this.errorMessage = 'No se pudo cargar la lista de incidencias. ' + (err.error?.message || err.statusText);
          this.isLoadingIncidents = false;
          this.cdr.detectChanges();
        });
      }
    });
  }

  calculateStats(): void {
    const total = this.incidents.length;
    this.incidentStats.open = this.incidents.filter(i => i.estadoItem?.codigo === 'ABIERTO' || i.estadoItem?.codigo === 'ASIGNADO').length;
    this.incidentStats.inProgress = this.incidents.filter(i => i.estadoItem?.codigo === 'EN_PROCESO').length;
    this.incidentStats.resolved = this.incidents.filter(i => i.estadoItem?.codigo === 'RESUELTO' || i.estadoItem?.codigo === 'CERRADO').length;
    this.incidentStats.total = total;
  }

  getProgressValue(status: string | undefined): number {
    switch (status?.toUpperCase()) {
      case 'ABIERTO': return 15;
      case 'ASIGNADO': return 40;
      case 'EN_PROCESO': return 70;
      case 'RESUELTO': return 100;
      case 'CERRADO': return 100;
      default: return 0;
    }
  }

  getStatusBadgeClass(status: string | undefined): string {
    switch (status?.toUpperCase()) {
      case 'ABIERTO': return 'badge-open';
      case 'ASIGNADO': return 'badge-assigned';
      case 'EN_PROCESO': return 'badge-progress';
      case 'RESUELTO':
      case 'CERRADO': return 'badge-resolved';
      default: return 'badge-default';
    }
  }

  getStatusColor(status: string | undefined): string {
    switch (status?.toUpperCase()) {
      case 'ABIERTO': return '#0ea5e9';
      case 'ASIGNADO': return '#6366f1';
      case 'EN_PROCESO': return '#f59e0b';
      case 'RESUELTO':
      case 'CERRADO': return '#10b981';
      default: return '#64748b';
    }
  }

  ngOnDestroy(): void {
    if (this.userSubscription) {
      this.userSubscription.unsubscribe();
    }
  }
}
