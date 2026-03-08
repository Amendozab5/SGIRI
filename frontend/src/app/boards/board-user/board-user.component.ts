import { Component, OnInit, OnDestroy, ChangeDetectorRef, NgZone } from '@angular/core';
import { CommonModule } from '@angular/common';
import { SharedStateService } from '../../_services/shared-state.service';
import { TicketService } from '../../_services/ticket.service';
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
    private masterDataService: MasterDataService,
    private cdr: ChangeDetectorRef,
    private zone: NgZone
  ) { }

  ngOnInit(): void {
    this.userSubscription = this.sharedState.currentUser$.subscribe((user: User | null) => {
      if (user) {
        this.username = user.username;
      }
    });

    this.loadFilterOptions();
    this.loadIncidents();
    this.loadGlobalStats(); // Cargar estadísticas globales sin filtros
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
