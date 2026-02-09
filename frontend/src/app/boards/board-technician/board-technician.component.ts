import { Component, OnInit } from '@angular/core';
import { CommonModule, NgClass } from '@angular/common';
import { Incident } from '../../models/incident';
import { IncidentService } from '../../_services/incident.service';
import { EIncidentStatus } from '../../models/EIncidentStatus.enum';
import { FormsModule } from '@angular/forms';

@Component({
  selector: 'app-board-technician',
  templateUrl: './board-technician.component.html',
  styleUrls: ['./board-technician.component.css'],
  standalone: true,
  imports: [CommonModule, NgClass, FormsModule]
})
export class BoardTechnicianComponent implements OnInit {
  incidents: Incident[] = [];
  errorMessage: string = '';
  isLoading: boolean = true;
  
  // Expose enum to the template
  public EIncidentStatus = EIncidentStatus;
  
  constructor(private incidentService: IncidentService) { }

  ngOnInit(): void {
    this.reloadIncidents();
  }

  reloadIncidents(): void {
    this.isLoading = true;
    this.errorMessage = '';
    this.incidentService.getAllIncidents().subscribe({
      next: (data: Incident[]) => {
        this.incidents = data;
        this.isLoading = false;
      },
      error: (err: any) => {
        this.errorMessage = 'No se pudieron cargar las incidencias. Por favor, intente más tarde.';
        console.error(err);
        this.isLoading = false;
      }
    });
  }

  assignToMe(incidentId: number): void {
    this.incidentService.assignToMe(incidentId).subscribe({
      next: (updatedIncident) => {
        const index = this.incidents.findIndex(inc => inc.id === incidentId);
        if (index !== -1) {
          this.incidents[index] = updatedIncident;
        }
      },
      error: (err) => {
        this.errorMessage = `Error al asignar la incidencia #${incidentId}.`;
        console.error(err);
      }
    });
  }

  updateStatus(incidentId: number, event: Event): void {
    const selectElement = event.target as HTMLSelectElement;
    const newStatus = selectElement.value as EIncidentStatus;

    if (!newStatus) return;

    this.incidentService.updateStatus(incidentId, newStatus).subscribe({
      next: (updatedIncident) => {
        const index = this.incidents.findIndex(inc => inc.id === incidentId);
        if (index !== -1) {
          this.incidents[index] = updatedIncident;
        }
      },
      error: (err) => {
        this.errorMessage = `Error al actualizar la incidencia #${incidentId}.`;
        console.error(err);
      }
    });
  }
}
