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
    this.incidentStats.open = this.incidents.filter(i => i.estadoItem?.codigo === 'ABIERTO' || i.estadoItem?.nombre === 'ABIERTO').length;
    this.incidentStats.inProgress = this.incidents.filter(i => i.estadoItem?.codigo === 'EN_PROCESO' || i.estadoItem?.nombre === 'EN_PROCESO').length;
    this.incidentStats.resolved = this.incidents.filter(i => i.estadoItem?.codigo === 'RESUELTO' || i.estadoItem?.nombre === 'RESUELTO' || i.estadoItem?.codigo === 'CERRADO').length;
  }

  getStatusBadgeClass(status: string | undefined): string {
    switch (status?.toUpperCase()) {
      case 'ABIERTO': return 'bg-info-subtle text-info';
      case 'EN_PROCESO': return 'bg-warning-subtle text-warning';
      case 'RESUELTO':
      case 'CERRADO': return 'bg-success-subtle text-success';
      default: return 'bg-secondary-subtle text-secondary';
    }
  }

  ngOnDestroy(): void {
    if (this.userSubscription) {
      this.userSubscription.unsubscribe();
    }
  }
}
