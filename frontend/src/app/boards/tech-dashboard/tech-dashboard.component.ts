import { Component, OnInit, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { TicketService } from '../../_services/ticket.service';
import { VisitaService } from '../../_services/visita.service';
import { CompanyService } from '../../_services/company.service';
import { TokenStorageService } from '../../_services/token-storage.service';
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
  date: string;
  time: string;
  title: string;
  client: string;
  address: string;
  isOverdue: boolean;
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

  techEvaluation = {
    avgRating: 0,
    totalEvaluations: 0,
    totalAtendidas: 0,
    qualityRating: 0,
    recentComments: [] as any[]
  };

  companyMap: Map<number, string> = new Map();

  constructor(
    private ticketService: TicketService,
    private visitaService: VisitaService,
    private companyService: CompanyService,
    private networkService: NetworkService,
    private tokenStorage: TokenStorageService,
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
      visitas: this.visitaService.getMyVisits().pipe(catchError(() => of([]))),
      network: this.networkService.getNetworkMap('PROVINCIA').pipe(catchError(() => of([])))
    }).subscribe({
      next: (res) => {
        // Mapeo de empresas
        res.companies.forEach(c => this.companyMap.set(c.id, c.nombreComercial));

        const processedTickets = (res.tickets || []).map(t => ({
          ...t,
          idUsuarioAsignado: t.idUsuarioAsignado || t.usuarioAsignado?.id,
          idEmpresa: t.idEmpresa || t.sucursal?.idEmpresa
        }));

        const todayObj = new Date();
        const y = todayObj.getFullYear();
        const m = String(todayObj.getMonth() + 1).padStart(2, '0');
        const d = String(todayObj.getDate()).padStart(2, '0');
        const todayStr = `${y}-${m}-${d}`;

        const todayVisits = (res.visitas || []).filter(v => {
          const isToday = v.fechaVisita === todayStr;
          const ticketStatus = v.ticket?.estadoItem?.codigo;
          const isTicketClosed = ['CERRADO', 'RESUELTO'].includes(ticketStatus || '');
          return isToday && !isTicketClosed;
        });

        this.processTickets(processedTickets);
        this.processVisitas(res.visitas);
        this.processNetwork(res.network);
        this.calculateKPIs(processedTickets, todayVisits);
        this.loadTechEvaluation();

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
        empresa: this.companyMap.get(t.idEmpresa!) || 'Empresa Interna',
        prioridad: t.prioridadItem?.codigo || 'MEDIA',
        status: t.estadoItem?.codigo || 'ABIERTO',
        statusLabel: t.estadoItem?.nombre || 'Abierto',
        tiempoRestante: t.prioridadItem?.codigo === 'URGENTE' ? 'Crítico' : undefined
      }));
  }

  private processVisitas(visitas: any[]): void {
    const today = new Date();
    const y = today.getFullYear();
    const m = String(today.getMonth() + 1).padStart(2, '0');
    const d = String(today.getDate()).padStart(2, '0');
    const todayStr = `${y}-${m}-${d}`;

    const activeStatuses = ['PROGRAMADA', 'REPROGRAMADA', 'CONFIRMADA'];

    this.visitasHoy = visitas
      .filter(v => {
        const isVisitActive = activeStatuses.includes(v.estado?.codigo);
        const ticketStatus = v.ticket?.estadoItem?.codigo;
        const isTicketClosed = ['CERRADO', 'RESUELTO'].includes(ticketStatus);
        return isVisitActive && !isTicketClosed;
      })
      .sort((a, b) => {
        const dateTimeA = a.fechaVisita + ' ' + (a.horaInicio || '00:00');
        const dateTimeB = b.fechaVisita + ' ' + (b.horaInicio || '00:00');
        return dateTimeA.localeCompare(dateTimeB);
      })
      .map(v => {
        const dateObj = new Date(v.fechaVisita + 'T12:00:00');
        const day = dateObj.getDate();
        const month = dateObj.toLocaleDateString('es-ES', { month: 'short' }).toUpperCase().replace('.', '');
        const isOverdue = v.fechaVisita < todayStr;

        return {
          date: `${day} ${month}`,
          time: (v.horaInicio || '').substring(0, 5),
          title: v.ticket?.asunto || 'Visita Técnica',
          client: (v.ticket?.cliente?.persona?.nombre || '') + ' ' + (v.ticket?.cliente?.persona?.apellido || ''),
          address: v.ticket?.sucursal?.nombre || 'Sucursal',
          isOverdue: isOverdue
        };
      })
      .slice(0, 6);
  }

  private processNetwork(nodes: NetworkMapData[]): void {
    this.networkStatus = nodes
      .filter(n => {
        const name = (n.zoneName || '').toUpperCase();
        return name !== 'ZONAS NO DELIMITADAS' && name !== 'ZONA NO DELIMITADA';
      })
      .map(n => ({
        region: n.zoneName,
        status: n.level === 'CRITICAL' ? 'danger' : n.level === 'WARNING' ? 'warning' : 'success',
        nodes: `${n.openTickets} Incidentes`,
        percentage: n.scoreFinal || 0
      }));
  }

  private calculateKPIs(tickets: Ticket[], visitas: any[]): void {
    const criticalCount = tickets.filter(t => t.prioridadItem?.codigo === 'URGENTE' || t.prioridadItem?.codigo === 'CRITICA').length;
    
    // Inclusión de estados que también significan trabajo para el técnico
    const assignedCount = tickets.filter(t => 
      ['ASIGNADO', 'EN_PROCESO', 'REQUIERE_VISITA', 'REPROGRAMADA'].includes(t.estadoItem?.codigo || '')
    ).length;

    this.kpis = [
      { label: 'Asignados', value: assignedCount, icon: 'bi-briefcase', class: 'info' },
      { label: 'Críticos', value: criticalCount, icon: 'bi-exclamation-octagon', class: 'danger', trend: criticalCount > 0 ? `+${criticalCount} activos` : '' },
      { label: 'Visitas Hoy', value: visitas.length, icon: 'bi-calendar-event', class: 'warning' },
      { label: 'Resueltos', value: tickets.filter(t => ['RESUELTO', 'CERRADO'].includes(t.estadoItem?.codigo || '')).length, icon: 'bi-check-all', class: 'success' },
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
    if (code === 'RESUELTO' || code === 'CERRADO') return 'status-success';
    return 'status-default';
  }

  private loadTechEvaluation(): void {
    const user = this.tokenStorage.getUser();
    if (!user || !user.id) return;

    this.ticketService.getTechnicianStats(user.id).subscribe(stats => {
      this.techEvaluation.avgRating = stats.promedio || 0;
      this.techEvaluation.totalEvaluations = stats.totalCalificados || 0;
      this.techEvaluation.totalAtendidas = stats.totalTickets || 0;
      this.techEvaluation.qualityRating = Number((stats.promedio || 0).toFixed(1));
      this.cdr.detectChanges();
    });

    this.ticketService.getAssignedTickets().subscribe(tickets => {
      this.techEvaluation.recentComments = tickets
        .filter(t => t.calificacionSatisfaccion && t.comentarioCalificacion)
        .sort((a, b) => new Date(b.fechaCierre!).getTime() - new Date(a.fechaCierre!).getTime())
        .slice(0, 2)
        .map(t => ({
          text: t.comentarioCalificacion,
          client: (t.cliente?.persona?.nombre || 'U') + ' ' + (t.cliente?.persona?.apellido || ''),
          rating: t.calificacionSatisfaccion
        }));
      this.cdr.detectChanges();
    });
  }
}
