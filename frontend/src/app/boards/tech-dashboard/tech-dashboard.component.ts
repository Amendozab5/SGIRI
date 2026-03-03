import { Component, OnInit, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { TicketService } from '../../_services/ticket.service';
import { VisitaService } from '../../_services/visita.service';
import { CompanyService } from '../../_services/company.service';
import { NetworkService, NetworkMapData } from '../../_services/network.service';
import { Ticket } from '../../models/ticket';
import { forkJoin, of } from 'rxjs';
import { catchError } from 'rxjs/operators';

interface TechKPI {
  label: string;
  value: string | number;
  icon: string;
  class: string;
  trend?: string;
}

interface PersonalTicket {
  id: string;
  asunto: string;
  sucursal: string;
  empresa: string;
  prioridad: string;
  status: string;
  statusLabel: string;
  tiempoRestante?: string;
}

interface Visit {
  time: string;
  title: string;
  client: string;
  address: string;
}

interface NetStatus {
  region: string;
  status: string;
  nodes: string;
  percentage: number;
}

@Component({
  selector: 'app-tech-dashboard',
  templateUrl: './tech-dashboard.component.html',
  styleUrls: ['./tech-dashboard.component.css'],
  standalone: true,
  imports: [CommonModule, RouterModule]
})
export class TechDashboardComponent implements OnInit {

  today: Date = new Date();
  isLoading: boolean = true;

  kpis: TechKPI[] = [];
  ticketsHoy: PersonalTicket[] = [];
  visitasHoy: Visit[] = [];
  networkStatus: NetStatus[] = [];

  companyMap: Map<number, string> = new Map();

  constructor(
    private ticketService: TicketService,
    private visitaService: VisitaService,
    private companyService: CompanyService,
    private networkService: NetworkService,
    private cdr: ChangeDetectorRef
  ) { }

  ngOnInit(): void {
    this.loadDashboardData();
  }

  loadDashboardData(): void {
    this.isLoading = true;

    // Rango de fechas para hoy
    const start = new Date();
    start.setHours(0, 0, 0, 0);
    const end = new Date();
    end.setHours(23, 59, 59, 999);

    const startStr = start.toISOString();
    const endStr = end.toISOString();

    forkJoin({
      tickets: this.ticketService.getAssignedTickets().pipe(catchError(() => of([]))),
      companies: this.companyService.getISPs().pipe(catchError(() => of([]))),
      visitas: this.visitaService.getVisitas(startStr, endStr).pipe(catchError(() => of([]))),
      network: this.networkService.getNetworkMap('REGION').pipe(catchError(() => of([])))
    }).subscribe({
      next: (res) => {
        // Mapeo de empresas
        res.companies.forEach(c => this.companyMap.set(c.id, c.nombreComercial));

        this.processTickets(res.tickets);
        this.processVisitas(res.visitas);
        this.processNetwork(res.network);
        this.calculateKPIs(res.tickets, res.visitas);

        this.isLoading = false;
        this.cdr.detectChanges();
      },
      error: (err) => {
        console.error('Error cargando datos del técnico', err);
        this.isLoading = false;
        this.cdr.detectChanges();
      }
    });
  }

  private processTickets(tickets: Ticket[]): void {
    this.ticketsHoy = tickets
      .slice(0, 4)
      .map(t => ({
        id: t.idTicket?.toString() || 'N/A',
        asunto: t.asunto || 'Sin asunto',
        sucursal: t.sucursal?.nombre || 'General',
        empresa: this.companyMap.get(t.idEmpresa) || 'Empresa Interna',
        prioridad: t.prioridadItem?.codigo || 'MEDIA',
        status: t.estadoItem?.codigo || 'ABIERTO',
        statusLabel: t.estadoItem?.nombre || 'Abierto',
        tiempoRestante: t.prioridadItem?.codigo === 'URGENTE' ? 'Crítico' : undefined
      }));
  }

  private processVisitas(visitas: any[]): void {
    this.visitasHoy = visitas.slice(0, 3).map(v => ({
      time: new Date(v.fechaProgramada).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
      title: v.motivo || 'Visita Técnica',
      client: v.ticket?.cliente?.persona?.nombre || 'Cliente Final',
      address: v.ticket?.sucursal?.nombre || 'Dirección'
    }));
  }

  private processNetwork(nodes: NetworkMapData[]): void {
    this.networkStatus = nodes.map(n => ({
      region: n.zoneName,
      status: n.level === 'CRITICAL' ? 'danger' : n.level === 'WARNING' ? 'warning' : 'success',
      nodes: `${n.openTickets} Incidentes`,
      percentage: 100 - (n.scoreFinal || 0)
    }));
  }

  private calculateKPIs(tickets: Ticket[], visitas: any[]): void {
    const criticalCount = tickets.filter(t => t.prioridadItem?.codigo === 'URGENTE' || t.prioridadItem?.codigo === 'CRITICA').length;
    const assignedCount = tickets.filter(t => t.estadoItem?.codigo === 'ASIGNADO' || t.estadoItem?.codigo === 'EN_PROCESO').length;

    this.kpis = [
      { label: 'Asignados', value: assignedCount, icon: 'bi-briefcase', class: 'info' },
      { label: 'Críticos', value: criticalCount, icon: 'bi-exclamation-octagon', class: 'danger', trend: criticalCount > 0 ? `+${criticalCount} activos` : '' },
      { label: 'Visitas Hoy', value: visitas.length, icon: 'bi-calendar-event', class: 'warning' },
      { label: 'Resueltos', value: tickets.filter(t => t.estadoItem?.codigo === 'RESUELTO').length, icon: 'bi-check-all', class: 'success' },
      { label: 'Estado Red', value: 'Óptimo', icon: 'bi-graph-up-arrow', class: 'primary' }
    ];
  }

  getPriorityClass(p: string): string {
    if (!p) return '';
    const code = p.toUpperCase();
    if (code === 'URGENTE' || code === 'CRITICA') return 'prio-urgent';
    if (code === 'ALTA') return 'prio-high';
    if (code === 'MEDIA') return 'prio-med';
    if (code === 'BAJA') return 'prio-low';
    return '';
  }

  getStatusClass(s: string): string {
    if (!s) return 'status-default';
    const code = s.toUpperCase();
    if (code === 'EN_PROCESO') return 'status-active';
    if (code === 'ASIGNADO') return 'status-pending';
    if (code === 'RESUELTO') return 'status-success';
    return 'status-default';
  }
}
