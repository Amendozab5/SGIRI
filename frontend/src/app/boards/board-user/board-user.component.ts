import { Component, OnInit, OnDestroy, ChangeDetectorRef, NgZone } from '@angular/core';
import { Router } from '@angular/router';
import { CommonModule } from '@angular/common';
import { SharedStateService } from '../../_services/shared-state.service';
import { TicketService } from '../../_services/ticket.service';
import { VisitaService } from '../../_services/visita.service';
import { MasterDataService } from '../../_services/master-data.service';
import { RouterModule } from '@angular/router';
import { Subscription } from 'rxjs';
import { User } from '../../models/user.model';
import { CatalogoItem } from '../../models/catalogo';
import { FormsModule, ReactiveFormsModule } from '@angular/forms';

@Component({
  selector: 'app-board-user',
  templateUrl: './board-user.component.html',
  styleUrls: ['./board-user.component.css'],
  standalone: true,
  imports: [CommonModule, RouterModule, FormsModule, ReactiveFormsModule]
})
export class BoardUserComponent implements OnInit, OnDestroy {
  username?: string;
  incidentStats: any = { open: 0, inProgress: 0, resolved: 0, total: 0 };
  incidents: any[] = [];
  isLoadingIncidents = true;
  myVisits: any[] = [];
  selectedVisitForDetails: any = null;
  errorMessage = '';

  // Pagination & Filtering
  currentPage = 0;
  pageSize = 6;
  totalElements = 0;
  totalPages = 0;
  searchTerm = '';
  selectedStatusId: number | null = null;
  selectedCategoryId: number | null = null;

  availableStatuses: CatalogoItem[] = [];
  availableCategories: CatalogoItem[] = [];

  private userSubscription: Subscription | undefined;

  constructor(
    private sharedState: SharedStateService,
    private ticketService: TicketService,
    private visitaService: VisitaService,
    private masterDataService: MasterDataService,
    private cdr: ChangeDetectorRef,
    private zone: NgZone,
    private router: Router
  ) { }

  ngOnInit(): void {
    this.userSubscription = this.sharedState.currentUser$.subscribe((user: User | null) => {
      if (user) {
        this.username = user.username;
      }
    });

    this.loadFilterOptions();
    this.loadIncidents();
    this.loadGlobalStats();
    this.loadMyVisits();
  }

  loadFilterOptions(): void {
    this.masterDataService.getCatalogoItems('ESTADO_TICKET', true).subscribe(items => {
      this.availableStatuses = items;
    });
    this.masterDataService.getCatalogoItems('CATEGORIA_TICKET', true).subscribe(items => {
      this.availableCategories = items;
    });
  }

  loadGlobalStats(): void {
    this.ticketService.getMyTickets().subscribe(data => {
      const all = data || [];
      this.incidentStats.open = all.filter((i: any) => i.estadoItem?.codigo === 'ABIERTO' || i.estadoItem?.codigo === 'ASIGNADO').length;
      this.incidentStats.inProgress = all.filter((i: any) => i.estadoItem?.codigo === 'EN_PROCESO').length;
      this.incidentStats.resolved = all.filter((i: any) => i.estadoItem?.codigo === 'RESUELTO' || i.estadoItem?.codigo === 'CERRADO').length;
      this.incidentStats.total = all.length;
      this.cdr.detectChanges();
    });
  }

  loadMyVisits(): void {
    this.visitaService.getMyVisits().subscribe(visits => {
      const today = new Date();
      today.setHours(0, 0, 0, 0);

      // Eliminación de duplicados y filtrado de estados/fechas
      const uniqueVisits = new Map();
      
      visits.forEach((v: any) => {
        if (!uniqueVisits.has(v.idVisita)) {
          const vDate = new Date(v.fechaVisita + 'T00:00:00');
          if (vDate >= today && v.estado.codigo !== 'CANCELADA' && v.estado.codigo !== 'FINALIZADA') {
            uniqueVisits.set(v.idVisita, v);
          }
        }
      });

      this.myVisits = Array.from(uniqueVisits.values());
      this.cdr.detectChanges();
    });
  }

  showVisitDetails(visit: any): void {
    // Puntox: Fix 'Empty Day' by creating a robust Date object
    // Separamos los componentes para evitar problemas de zona horaria (UTC vs Local)
    const [year, month, day] = visit.fechaVisita.split('-').map(Number);
    const normalizedDate = new Date(year, month - 1, day);

    this.selectedVisitForDetails = {
      ...visit,
      fechaFormateada: normalizedDate
    };
    this.cdr.detectChanges();
  }

  closeVisitDetails(): void {
    this.selectedVisitForDetails = null;
    this.cdr.detectChanges();
  }

  goToTicket(idTicket: number): void {
    if (!idTicket) return;
    
    // Cerramos el modal primero (opcional, pero ayuda a la UX)
    this.selectedVisitForDetails = null;
    this.cdr.detectChanges();
    
    // Navegación programática
    this.router.navigate(['/home/user/ticket', idTicket]);
  }

  loadIncidents(): void {
    this.isLoadingIncidents = true;
    this.cdr.detectChanges();

    this.ticketService.getMyTicketsPaged(
      this.currentPage,
      this.pageSize,
      this.searchTerm,
      this.selectedStatusId ?? undefined,
      this.selectedCategoryId ?? undefined
    ).subscribe({
      next: (data: any) => {
        this.zone.run(() => {
          this.incidents = data.content;
          this.totalElements = data.totalElements;
          this.totalPages = data.totalPages;
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

  onSearch(): void {
    this.currentPage = 0;
    this.loadIncidents();
  }

  onFilterChange(): void {
    this.currentPage = 0;
    this.loadIncidents();
  }

  selectStatus(id: number | null): void {
    this.selectedStatusId = id;
    this.onFilterChange();
  }

  selectCategory(id: number | null): void {
    this.selectedCategoryId = id;
    this.onFilterChange();
  }

  getStatusIcon(code: string | undefined): string {
    switch (code?.toUpperCase()) {
      case 'ABIERTO': return 'bi-envelope';
      case 'ASIGNADO': return 'bi-person-check';
      case 'EN_PROCESO': return 'bi-gear-wide-connected';
      case 'REPROGRAMADA': return 'bi-calendar-event';
      case 'RESUELTO': return 'bi-check-circle-fill';
      case 'CERRADO': return 'bi-shield-check';
      case 'RECHAZADO': return 'bi-x-circle';
      case 'REQUIERE_VISITA': return 'bi-truck';
      default: return 'bi-tag';
    }
  }

  changePage(page: number): void {
    if (page >= 0 && page < this.totalPages) {
      this.currentPage = page;
      this.loadIncidents();
      window.scrollTo({ top: 0, behavior: 'smooth' });
    }
  }

  getPagesArray(): number[] {
    const pages = [];
    for (let i = 0; i < this.totalPages; i++) {
      pages.push(i);
    }
    return pages;
  }

  getProgressValue(status: string | undefined): number {
    switch (status?.toUpperCase()) {
      case 'ABIERTO': return 15;
      case 'REPROGRAMADA': return 25;
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
      case 'REPROGRAMADA': return 'badge-reprogramada';
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
      case 'REPROGRAMADA': return '#64748b';
      case 'ASIGNADO': return '#6366f1';
      case 'EN_PROCESO': return '#f59e0b';
      case 'RESUELTO':
      case 'CERRADO': return '#10b981';
      default: return '#64748b';
    }
  }

  getInitials(name: any): string {
    const safeName = String(name || '');
    if (!safeName || safeName === 'undefined' || safeName === 'null') return '??';
    const parts = safeName.split(' ');
    if (parts.length >= 2 && parts[0] && parts[1]) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return safeName.substring(0, 2).toUpperCase();
  }

  getAvatarColor(name: any): string {
    const safeName = String(name || '');
    if (!safeName || safeName === 'undefined' || safeName === 'null') return '#64748b';
    let hash = 0;
    for (let i = 0; i < safeName.length; i++) {
      hash = safeName.charCodeAt(i) + ((hash << 5) - hash);
    }
    const h = hash % 360;
    return `hsl(${h}, 60%, 45%)`;
  }

  ngOnDestroy(): void {
    if (this.userSubscription) {
      this.userSubscription.unsubscribe();
    }
  }
}
