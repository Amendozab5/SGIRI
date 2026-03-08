import { Component, OnInit, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { TicketService } from '../../_services/ticket.service';
import { UserService } from '../../_services/user.service';
import { CompanyService } from '../../_services/company.service';
import { Ticket } from '../../models/ticket';
import { Empresa } from '../../models/empresa';
import { UserAdminView } from '../../models/user-admin-view.model';
import { forkJoin, of } from 'rxjs';
import { catchError } from 'rxjs/operators';

interface KPI {
  label: string;
  value: string;
  icon: string;
  color: string;
  trend: string;
}

interface Activity {
  user: string;
  action: string;
  time: string;
  icon: string;
}

interface MiniTicket {
  id: string;
  client: string;
  companyName: string;
  subject: string;
  status: string;
  priority: string;
}

interface TeamMember {
  name: string;
  load: number;
  color: string;
}

interface QuickAction {
  label: string;
  link: string;
  icon: string;
}

@Component({
  selector: 'app-admin-dashboard',
  templateUrl: './admin-dashboard.component.html',
  styleUrls: ['./admin-dashboard.component.css'],
  standalone: true,
  imports: [CommonModule, RouterModule]
})
export class AdminDashboardComponent implements OnInit {

  today: Date = new Date();
  isLoading: boolean = true;

  kpis: KPI[] = [];
  recentActivity: Activity[] = [];
  pendingTickets: MiniTicket[] = [];
  teamLoad: TeamMember[] = [];

  companyMap: Map<number, string> = new Map();

  quickActions: QuickAction[] = [
    { label: 'Usuarios', link: '/home/gestion-usuarios', icon: 'bi-people' },
    { label: 'Empleados', link: '/home/gestion-empleados', icon: 'bi-person-badge' },
    { label: 'Tickets', link: '/home/asignacion-tickets', icon: 'bi-shuffle' },
    { label: 'Catálogos', link: '/home/gestion-catalogos', icon: 'bi-journal-check' },
    { label: 'Red', link: '/home/network-map', icon: 'bi-geo-alt' }
  ];

  constructor(
    private ticketService: TicketService,
    private userService: UserService,
    private companyService: CompanyService,
    private cdr: ChangeDetectorRef
  ) { }

  ngOnInit(): void {
    this.loadDashboardData();
  }

  loadDashboardData(): void {
    this.isLoading = true;

    forkJoin({
      tickets: this.ticketService.getAllTickets().pipe(catchError(() => of([]))),
      technicians: this.userService.getAllUsers('TECNICO').pipe(catchError(() => of([]))),
      companies: this.companyService.getISPs().pipe(catchError(() => of([])))
    }).subscribe({
      next: (res) => {
        console.log('Dashboard Data Loaded:', res);

        // Build Company Map
        if (res.companies) {
          res.companies.forEach(c => this.companyMap.set(c.id, c.nombreComercial));
        }

        // Map tickets once to ensures transient IDs are available for filtering
        const processedTickets = (res.tickets || []).map(t => ({
          ...t,
          idUsuarioAsignado: t.idUsuarioAsignado || t.usuarioAsignado?.id,
          idEmpresa: t.idEmpresa || t.sucursal?.idEmpresa
        }));

        this.processTickets(processedTickets);
        this.processTechnicians(res.technicians || [], processedTickets);
        this.processKPIs(processedTickets, res.technicians || []);

        this.isLoading = false;
        this.cdr.detectChanges();
      },
      error: (err) => {
        console.error('Critical error in Dashboard forkJoin', err);
        this.isLoading = false;
        this.cdr.detectChanges();
      }
    });
  }

  private processTickets(tickets: Ticket[]): void {
    // 1. Pending/Priority Tickets
    this.pendingTickets = tickets
      .filter(t => t.estadoItem?.codigo !== 'CERRADO' && t.estadoItem?.codigo !== 'RESUELTO')
      .sort((a, b) => (b.idTicket || 0) - (a.idTicket || 0)) // Recent first
      .slice(0, 5)
      .map(t => ({
        id: t.idTicket?.toString() || '',
        client: t.cliente?.persona ? `${t.cliente.persona.nombre} ${t.cliente.persona.apellido}` : 'Cédula: ' + t.cedulaCliente,
        companyName: this.companyMap.get(t.idEmpresa!) || 'Entidad Int.',
        subject: t.asunto,
        status: t.estadoItem?.nombre || 'Abierto',
        priority: t.prioridadItem?.nombre || 'Media'
      }));

    // 2. Recent Activity (based on creation and status changes if available, otherwise just latest tickets)
    this.recentActivity = tickets
      .sort((a, b) => {
        const dateA = a.fechaCreacion ? new Date(a.fechaCreacion).getTime() : 0;
        const dateB = b.fechaCreacion ? new Date(b.fechaCreacion).getTime() : 0;
        return dateB - dateA;
      })
      .slice(0, 4)
      .map(t => ({
        user: t.usuarioCreador?.username || 'Sistema',
        action: `Nuevo ticket: ${t.asunto}`,
        time: this.formatTimeAgo(t.fechaCreacion),
        icon: 'bi-ticket-perforated'
      }));
  }

  private processTechnicians(techs: UserAdminView[], tickets: Ticket[]): void {
    const activeTickets = tickets.filter(t => t.estadoItem?.codigo !== 'CERRADO' && t.estadoItem?.codigo !== 'RESUELTO');

    this.teamLoad = techs.slice(0, 5).map(tech => {
      const techTickets = activeTickets.filter(t => t.idUsuarioAsignado === tech.id).length;
      // Load calculation: count/8 capped at 100%
      const load = Math.min(Math.round((techTickets / 8) * 100), 100);

      return {
        name: (tech.fullName && tech.fullName !== 'N/A') ? tech.fullName : tech.username,
        load: load,
        color: load > 80 ? '#dc2626' : (load > 50 ? '#f59e0b' : '#2563eb')
      };
    });
  }

  private processKPIs(tickets: Ticket[], techs: UserAdminView[]): void {
    // Current "Active" tickets are those not resolved or closed
    const activeTickets = tickets.filter(t => t.estadoItem?.codigo !== 'CERRADO' && t.estadoItem?.codigo !== 'RESUELTO');
    
    const openCount = activeTickets.length;
    const criticalCount = activeTickets.filter(t => (t.prioridadItem?.codigo === 'ALTA' || t.prioridadItem?.codigo === 'URGENTE' || t.idPrioridadItem === 3)).length;
    const activeTechs = techs.filter(u => u.estado === 'ACTIVO').length;

    // SLA calculation: Resolved vs Total (simplified)
    const resolved = tickets.filter(t => t.estadoItem?.codigo === 'RESUELTO' || t.estadoItem?.codigo === 'CERRADO').length;
    const slaPercent = tickets.length > 0 ? Math.round((resolved / tickets.length) * 100) : 100;

    this.kpis = [
      { label: 'Tickets Activos', value: openCount.toString(), icon: 'bi-ticket-detailed', color: '#2563eb', trend: 'Actual' },
      { label: 'Técnicos Online', value: activeTechs.toString(), icon: 'bi-person-badge', color: '#7c3aed', trend: 'Sistema' },
      { label: 'Incidencias Críticas', value: criticalCount.toString(), icon: 'bi-exclamation-octagon', color: '#dc2626', trend: 'Prioridad' },
      { label: 'Resolución General', value: `${slaPercent}%`, icon: 'bi-shield-check', color: '#16a34a', trend: 'Total' }
    ];
  }

  private formatTimeAgo(date?: Date | string): string {
    if (!date) return 'Recientemente';
    const now = new Date();
    const past = new Date(date);
    const diffMs = now.getTime() - past.getTime();
    const diffMins = Math.floor(diffMs / 60000);

    if (diffMins < 60) return `hace ${diffMins} min`;
    const diffHours = Math.floor(diffMins / 60);
    if (diffHours < 24) return `hace ${diffHours} h`;
    return past.toLocaleDateString();
  }
}
