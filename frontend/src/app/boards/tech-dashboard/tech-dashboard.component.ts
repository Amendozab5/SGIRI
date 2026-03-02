import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';

@Component({
    selector: 'app-tech-dashboard',
    template: `
    <div class="tech-dashboard-container">
      <div class="dashboard-header text-center">
        <h1 class="font-weight-bold">Dashboard de Técnico</h1>
        <p class="subtitle">Resumen general de tareas, monitoreo de red y agenda de visitas para técnicos.</p>
      </div>
      
      <div class="cards-grid">
        <!-- Tarjeta 1 (Incidencias) -->
        <div class="tech-card blue-gradient" routerLink="/home/tech-tickets">
          <div class="card-icon">
            <i class="bi bi-tools"></i>
          </div>
          <div class="card-content">
            <h3>Mis Incidencias Asignadas</h3>
            <p>Visualiza y gestiona los tickets de soporte que te han sido asignados.</p>
          </div>
          <div class="card-action">
            <span>Ver Incidencias</span>
            <i class="bi bi-arrow-right"></i>
          </div>
        </div>

        <!-- Tarjeta 2 (Estado de Red) -->
        <div class="tech-card purple-gradient" routerLink="/home/network-map">
          <div class="card-icon">
            <i class="bi bi-geo-alt-fill"></i>
          </div>
          <div class="card-content">
            <h3>Estado de Red Nacional</h3>
            <p>Monitorea y visualiza en tiempo real el estado de los nodos a nivel nacional.</p>
          </div>
          <div class="card-action">
            <span>Ir al Mapa de Red</span>
            <i class="bi bi-arrow-right"></i>
          </div>
        </div>

        <!-- Tarjeta 3 (Agenda) -->
        <div class="tech-card coral-gradient" routerLink="/home/agenda">
          <div class="card-icon">
            <i class="bi bi-calendar3"></i>
          </div>
          <div class="card-content">
            <h3>Agenda de Visitas</h3>
            <p>Consulta y planifica tu calendario de visitas técnicas programadas.</p>
          </div>
          <div class="card-action">
            <span>Ver Agenda</span>
            <i class="bi bi-arrow-right"></i>
          </div>
        </div>
      </div>
    </div>
  `,
    styleUrls: ['./tech-dashboard.component.css'],
    standalone: true,
    imports: [CommonModule, RouterModule]
})
export class TechDashboardComponent implements OnInit {

    constructor() { }

    ngOnInit(): void {
    }

}
