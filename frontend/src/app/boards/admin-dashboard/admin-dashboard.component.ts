import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { TokenStorageService } from '../../_services/token-storage.service';

@Component({
  selector: 'app-admin-dashboard',
  template: `
    <div class="admin-dashboard-container">
      <div class="dashboard-header text-center">
        <h1 class="font-weight-bold">Dashboard General de Administrador</h1>
        <p class="subtitle">Resumen general del sistema, estadísticas y accesos rápidos a las funcionalidades administrativas.</p>
      </div>
      
      <div class="cards-grid">
        <!-- Tarjeta 1: Gestión de Usuarios (Sólo MASTER) -->
        <div class="admin-card blue-gradient" routerLink="/home/gestion-usuarios" *ngIf="showUserManagement">
          <div class="card-icon">
            <i class="bi bi-people-fill"></i>
          </div>
          <div class="card-content">
            <h3>Gestión de Usuarios</h3>
            <p>Administra las cuentas de usuario, asigna roles y gestiona permisos del sistema.</p>
          </div>
          <div class="card-action">
            <span>Ir a Gestión</span>
            <i class="bi bi-arrow-right"></i>
          </div>
        </div>

        <!-- Tarjeta 2: Asignación de Tickets (MASTER y TECNICOS) -->
        <div class="admin-card blue-gradient" routerLink="/home/asignacion-tickets" *ngIf="showTicketAssignment">
          <div class="card-icon">
            <i class="bi bi-ticket-perforated-fill"></i>
          </div>
          <div class="card-content">
            <h3>Asignación de Tickets</h3>
            <p>Distribuye incidencias entre el equipo técnico y gestiona su carga de trabajo.</p>
          </div>
          <div class="card-action">
            <span>Ver Tickets</span>
            <i class="bi bi-arrow-right"></i>
          </div>
        </div>

        <!-- Tarjeta 3: Reportes -->
        <div class="admin-card purple-gradient">
          <div class="card-icon">
            <i class="bi bi-bar-chart-fill"></i>
          </div>
          <div class="card-content">
            <h3>Reportes</h3>
            <p>Genera y visualiza informes detallados y estadísticas del rendimiento del sistema.</p>
          </div>
          <div class="card-action">
            <span>Ver Reportes</span>
            <i class="bi bi-arrow-right"></i>
          </div>
        </div>

        <!-- Tarjeta 4: Configuración -->
        <div class="admin-card coral-gradient">
          <div class="card-icon">
            <i class="bi bi-gear-fill"></i>
          </div>
          <div class="card-content">
            <h3>Configuración</h3>
            <p>Ajusta y personaliza las configuraciones y parámetros generales del sistema SGIM.</p>
          </div>
          <div class="card-action">
            <span>Configurar</span>
            <i class="bi bi-arrow-right"></i>
          </div>
        </div>
      </div>
    </div>
  `,
  styleUrls: ['./admin-dashboard.component.css'],
  standalone: true,
  imports: [CommonModule, RouterModule]
})
export class AdminDashboardComponent implements OnInit {
  showUserManagement = false;
  showTicketAssignment = false;

  constructor(private tokenStorage: TokenStorageService) { }

  ngOnInit(): void {
    const user = this.tokenStorage.getUser();
    if (user && user.roles) {
      const roles = user.roles;
      const isMaster = roles.includes('ROLE_ADMIN_MASTER');
      const isTechAdmin = roles.includes('ROLE_ADMIN_TECNICOS');

      this.showUserManagement = isMaster;
      this.showTicketAssignment = isMaster || isTechAdmin;
    }
  }
}
