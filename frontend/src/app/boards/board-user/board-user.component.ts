import { Component, OnInit, OnDestroy } from '@angular/core';
import { CommonModule } from '@angular/common';
import { SharedStateService } from '../../_services/shared-state.service';
import { IncidentService } from '../../_services/incident.service';
import { RouterModule } from '@angular/router';
import { Incident } from '../../models/incident';
import { Subscription } from 'rxjs';
import { User } from '../../models/user.model';
import { EIncidentStatus } from '../../models/EIncidentStatus.enum';

@Component({
  selector: 'app-board-user',
  templateUrl: './board-user.component.html',
  styleUrls: ['./board-user.component.css'],
  standalone: true,
  imports: [CommonModule, RouterModule]
})
export class BoardUserComponent implements OnInit, OnDestroy {
  username?: string;
  incidentStats = { pendiente: 0, enProceso: 0, resuelta: 0 };
  incidents: Incident[] = [];
  isLoading = true;
  errorMessage = '';
  private userSubscription: Subscription | undefined;

  constructor(
    private sharedState: SharedStateService,
    private incidentService: IncidentService,
  ) { }

  ngOnInit(): void {
    this.userSubscription = this.sharedState.currentUser$.subscribe((user: User | null) => {
      if (user) {
        this.username = user.username;
      }
    });

    this.incidentService.getMyIncidents().subscribe({
      next: (data: Incident[]) => {
        this.incidents = data;
        this.calculateStats();
        this.isLoading = false;
      },
      error: (err: any) => {
        console.error(err);
        this.errorMessage = 'No se pudo cargar la lista de incidencias. ' + (err.error?.message || err.message);
        this.isLoading = false;
      }
    });
  }

  calculateStats(): void {
    this.incidentStats = { pendiente: 0, enProceso: 0, resuelta: 0 };
    for (const incident of this.incidents) {
      switch (incident.status) {
        case EIncidentStatus.PENDIENTE:
          this.incidentStats.pendiente++;
          break;
        case EIncidentStatus.EN_PROCESO:
          this.incidentStats.enProceso++;
          break;
        case EIncidentStatus.RESUELTA:
          this.incidentStats.resuelta++;
          break;
      }
    }
  }

  ngOnDestroy(): void {
    if (this.userSubscription) {
      this.userSubscription.unsubscribe();
    }
  }
}
