import { Component, OnInit, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule, ReactiveFormsModule, FormControl } from '@angular/forms';
import { AuditService } from '../../_services/audit.service';
import { AuditTimeline, AuditDetail } from '../../models/audit.model';
import { debounceTime, distinctUntilChanged } from 'rxjs/operators';

@Component({
  selector: 'app-audit-management',
  standalone: true,
  imports: [CommonModule, FormsModule, ReactiveFormsModule],
  templateUrl: './audit-management.component.html',
  styleUrl: './audit-management.component.css'
})
export class AuditManagementComponent implements OnInit {
  
  // Data
  events: AuditTimeline[] = [];
  selectedEvent?: AuditDetail;
  
  // State
  isLoading = false;
  totalElements = 0;
  totalPages = 0;
  currentPage = 0;
  pageSize = 20;
  showModal = false; // Control de modal por estado
  showAdvancedFilters = false; // Control de filtros por estado
  
  // Filters
  filters = {
    startDate: '',
    endDate: '',
    modulo: '',
    accion: '',
    username: '',
    exito: '' as any,
    tabla: '',
    idRegistro: ''
  };

  searchControl = new FormControl('');

  constructor(
    private auditService: AuditService,
    private cdr: ChangeDetectorRef
  ) {}

  ngOnInit(): void {
    // Configurar fechas por defecto (últimas 24 horas) para carga acelerada
    this.setDefaultDates();
    
    // Carga inicial inmediata
    this.loadTimeline();
    
    // Suscripción al buscador con guardas para evitar cargas duplicadas
    this.searchControl.valueChanges.pipe(
      debounceTime(400),
      distinctUntilChanged()
    ).subscribe(value => {
      const newVal = (value || '').trim();
      if (this.filters.username !== newVal) {
        this.filters.username = newVal;
        this.currentPage = 0;
        this.loadTimeline();
      }
    });
  }

  private setDefaultDates(): void {
    const now = new Date();
    const yesterday = new Date();
    yesterday.setHours(now.getHours() - 24);

    // Formatear para datetime-local (yyyy-MM-ddThh:mm)
    const formatDate = (date: Date) => {
      const pad = (num: number) => num.toString().padStart(2, '0');
      return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}T${pad(date.getHours())}:${pad(date.getMinutes())}`;
    };

    this.filters.startDate = formatDate(yesterday);
    this.filters.endDate = formatDate(now);
  }

  loadTimeline(): void {
    // Evitar múltiples cargas simultáneas si ya está cargando
    if (this.isLoading) return;
    
    this.isLoading = true;
    this.auditService.getTimeline(this.filters, this.currentPage, this.pageSize)
      .subscribe({
        next: (response) => {
          this.events = response.content || [];
          this.totalElements = response.totalElements || 0;
          this.totalPages = response.totalPages || 0;
          this.isLoading = false;
          this.cdr.detectChanges(); // Forzar actualización de UI
        },
        error: (err) => {
          console.error('Error loading audit timeline', err);
          this.isLoading = false;
          this.cdr.detectChanges(); // Asegurar que el spinner se oculte
          // Fallback a mocks solo si es crítico
          if (this.events.length === 0) {
            this.setMockData();
          }
        }
      });
  }

  applyFilters(): void {
    this.currentPage = 0;
    this.loadTimeline();
  }

  resetFilters(): void {
    this.filters = {
      startDate: '',
      endDate: '',
      modulo: '',
      accion: '',
      username: '',
      exito: '',
      tabla: '',
      idRegistro: ''
    };
    this.setDefaultDates(); // Reestablecer a rango seguro
    this.searchControl.setValue('', { emitEvent: false });
    this.currentPage = 0;
    this.loadTimeline();
  }

  toggleAdvancedFilters(): void {
    this.showAdvancedFilters = !this.showAdvancedFilters;
  }

  viewDetail(eventKey: string): void {
    if (!eventKey) return;
    
    // Mostramos un indicativo visual de carga si fuera necesario, 
    // pero por ahora simplemente aseguramos que el modal solo se abra con datos.
    this.auditService.getEventDetail(eventKey).subscribe({
      next: (detail) => {
        if (detail) {
          this.selectedEvent = detail;
          this.showModal = true;
          this.cdr.detectChanges(); // Force UI update on first click
          // Forzar scroll al inicio del modal si es necesario
          window.scrollTo(0, 0);
        } else {
          console.warn('Detalle devuelto vacío para:', eventKey);
        }
      },
      error: (err) => {
        console.error('Error al cargar detalle:', err);
        alert('No se pudo cargar el detalle del evento. Verifique la conexión o el ID.');
      }
    });
  }

  closeModal(): void {
    this.showModal = false;
    this.cdr.detectChanges(); // Update UI immediately
    // Agregamos un pequeño delay para limpiar el objeto y evitar saltos visuales en la animación de cerrado
    setTimeout(() => {
      this.selectedEvent = undefined;
      this.cdr.detectChanges();
    }, 200);
  }

  onPageChange(page: number): void {
    this.currentPage = page;
    this.loadTimeline();
  }

  private setMockData(): void {
    this.events = [
      {
        eventKey: 'EV-101',
        tipoEntidad: 'EVENTO',
        fecha: new Date().toISOString(),
        modulo: 'USUARIOS',
        accion: 'UPDATE',
        descripcion: 'Actualización administrativa de rol de usuario',
        usuarioBd: 'admin_master',
        ipOrigen: '192.168.1.50',
        exito: true,
        tablaAfectada: 'usuarios'
      },
      {
        eventKey: 'EV-105',
        tipoEntidad: 'EVENTO',
        fecha: new Date(Date.now() - 300000).toISOString(),
        modulo: 'AUTH',
        accion: 'LOGOUT',
        descripcion: 'Cierre de sesión de usuario',
        usuarioBd: 'soge_user',
        exito: true
      },
      {
        eventKey: 'LG-202',
        tipoEntidad: 'LOGIN',
        fecha: new Date(Date.now() - 3600000).toISOString(),
        modulo: 'AUTH',
        accion: 'LOGIN',
        descripcion: 'Inicio de sesión exitoso',
        usuarioBd: 'soge_user',
        ipOrigen: '201.244.1.10',
        exito: true
      }
    ];
    this.totalElements = 3;
    this.totalPages = 1;
  }

  // Visual helpers
  getActorDisplay(event: AuditTimeline): string {
    // Priorizamos el actor humano (username aplicativo) resuelto por el JOIN en la vista
    if (event.actor && event.actor !== 'null') return event.actor;
    
    // Si no hay actor humano pero hay usuario_bd técnico
    if (event.usuarioBd && event.usuarioBd !== 'null') return event.usuarioBd;
    
    return 'Sistema / Cliente';
  }

  getActorInitials(event: AuditTimeline): string {
    const actor = this.getActorDisplay(event);
    if (actor === 'Sistema / Cliente') return 'S';
    return actor.substring(0, 2).toUpperCase();
  }

  getModuloBadgeClass(modulo: string): string {
    const mod = modulo?.toLowerCase();
    return `badge-premium badge-${mod}`;
  }

  getAccionBadgeClass(accion: string): string {
    return ''; // No longer used in premium HTML
  }
}
