import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ActivatedRoute, Router, RouterModule } from '@angular/router';
import { FormsModule } from '@angular/forms';
import { TicketService } from '../../_services/ticket.service';
import { TokenStorageService } from '../../_services/token-storage.service';

@Component({
  selector: 'app-ticket-assign-panel',
  standalone: true,
  imports: [CommonModule, RouterModule, FormsModule],
  templateUrl: './ticket-assign-panel.component.html',
  styleUrls: ['./ticket-assign-panel.component.css']
})
export class TicketAssignPanelComponent implements OnInit {
  ticketId: number = 0;
  ticket: any = null;
  technicians: any[] = [];
  filteredTechnicians: any[] = [];
  
  loading = true;
  submitting = false;
  searchTerm: string = '';
  
  // Selection
  selectedTechId: number | null = null;
  
  // Grouped Technicians
  groupedTechnicians: { [cargo: string]: any[] } = {};
  
  // Detail sidebar
  selectedTechForDetail: any = null;
  techDocuments: any[] = [];
  loadingDocs = false;
  programarVisita = false;

  constructor(
    private route: ActivatedRoute,
    private router: Router,
    private ticketService: TicketService,
    private tokenService: TokenStorageService
  ) {}

  ngOnInit(): void {
    const id = this.route.snapshot.paramMap.get('id');
    if (id) {
      this.ticketId = +id;
      this.loadTicket();
      this.loadTechnicians();
    }
  }

  loadTicket() {
    this.ticketService.getTicketById(this.ticketId).subscribe({
      next: (data) => this.ticket = data,
      error: (err) => console.error('Error loading ticket', err)
    });
  }

  loadTechnicians() {
    this.loading = true;
    this.ticketService.getDetailedTechnicians().subscribe({
      next: (data) => {
        this.technicians = data;
        this.filteredTechnicians = data;
        this.groupTechniciansByCargo();
        this.loading = false;
      },
      error: (err) => {
        console.error('Error loading technicians', err);
        this.loading = false;
      }
    });
  }

  groupTechniciansByCargo() {
    this.groupedTechnicians = {};
    for (let tech of this.filteredTechnicians) {
      const cargo = tech.cargo || 'Sin Cargo';
      if (!this.groupedTechnicians[cargo]) {
        this.groupedTechnicians[cargo] = [];
      }
      this.groupedTechnicians[cargo].push(tech);
    }
  }

  onSearch() {
    if (!this.searchTerm.trim()) {
      this.filteredTechnicians = this.technicians;
      this.groupTechniciansByCargo();
      return;
    }
    const term = this.searchTerm.toLowerCase();
    this.filteredTechnicians = this.technicians.filter(t => 
      t.nombre.toLowerCase().includes(term) || 
      t.apellido.toLowerCase().includes(term) ||
      t.cargo.toLowerCase().includes(term) ||
      t.area.toLowerCase().includes(term) ||
      (t.cedula && t.cedula.toLowerCase().includes(term))
    );
    this.groupTechniciansByCargo();
  }

  toggleSelection(techId: number) {
    if (this.selectedTechId === techId) {
      this.selectedTechId = null;
    } else {
      this.selectedTechId = techId;
    }
  }

  isSelected(techId: number): boolean {
    return this.selectedTechId === techId;
  }

  selectForDetail(tech: any) {
    this.selectedTechForDetail = tech;
    this.loadTechDocuments(tech.userId);
  }

  loadTechDocuments(userId: number) {
    this.loadingDocs = true;
    this.ticketService.getTechnicianDocuments(userId).subscribe({
      next: (docs) => {
        this.techDocuments = docs;
        this.loadingDocs = false;
      },
      error: (err) => {
        console.error('Error loading docs', err);
        this.loadingDocs = false;
      }
    });
  }

  assign() {
    if (!this.selectedTechId) return;
    
    this.submitting = true;
    
    const visit = this.programarVisita;
    
    // Single assignment only
    this.ticketService.assignTicket(this.ticketId, this.selectedTechId).subscribe({
      next: () => {
        if (visit) {
          this.ticketService.updateStatus(this.ticketId, 'REQUIERE_VISITA', 'Visita programada por el administrador durante la asignación inicial.').subscribe({
            next: () => {
              this.submitting = false;
              this.router.navigate(['/home/user/ticket', this.ticketId]);
            }
          });
        } else {
          this.submitting = false;
          this.router.navigate(['/home/user/ticket', this.ticketId]);
        }
      },
      error: (err) => {
        this.submitting = false;
        alert('Error al asignar ticket: ' + (err.error?.message || err.message));
      }
    });
  }

  getSelectedTech() {
    if (!this.selectedTechId) return null;
    return this.technicians.find(t => t.userId === this.selectedTechId);
  }

  goBack() {
    this.router.navigate(['/home/user/ticket', this.ticketId]);
  }
}
