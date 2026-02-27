import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router'; // Import RouterModule

@Component({
  selector: 'app-admin-dashboard',
  template: `
    <div class="admin-dashboard-container">
      <div class="dashboard-header text-center">
        <h1 class="font-weight-bold">Dashboard General de Administrador</h1>
        <p class="subtitle">Resumen general del sistema, estadísticas y accesos rápidos a las funcionalidades administrativas.</p>
      </div>
      
      <div class="cards-grid">
        <!-- Tarjeta 1 -->
        <div class="admin-card blue-gradient" routerLink="/home/gestion-usuarios">
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

        <!-- Tarjeta 2 -->
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

        <!-- Tarjeta 3 -->
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

        <!-- Tarjeta 4 (Asignación) -->
        <div class="admin-card blue-gradient" routerLink="/home/asignacion-tickets">
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
      </div>
    </div>
  `,
  styleUrls: ['./admin-dashboard.component.css'],
  standalone: true,
  imports: [CommonModule, RouterModule] // Add CommonModule here
})
export class AdminDashboardComponent implements OnInit {

  constructor() { }

  ngOnInit(): void {
  }

}
