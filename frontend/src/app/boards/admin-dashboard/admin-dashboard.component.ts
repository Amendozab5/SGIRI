import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router'; // Import RouterModule

@Component({
  selector: 'app-admin-dashboard',
  template: `
    <div class="container">
      <header class="jumbotron">
        <h1 class="text-center">Bienvenido al Dashboard General de Administrador</h1>
        <p class="text-center">Aquí podrás ver un resumen general del sistema, estadísticas y accesos rápidos a las funcionalidades administrativas.</p>
      </header>
      <div class="row text-center">
        <div class="col-md-4">
          <div class="card">
            <div class="card-body">
              <h5 class="card-title">Gestión de Usuarios</h5>
              <p class="card-text">Administra las cuentas de usuario, roles y permisos.</p>
              <a routerLink="/home/gestion-usuarios" class="btn btn-primary">Ir a Gestión de Usuarios</a>
            </div>
          </div>
        </div>
        <div class="col-md-4">
          <div class="card">
            <div class="card-body">
              <h5 class="card-title">Reportes</h5>
              <p class="card-text">Genera y visualiza informes del sistema.</p>
              <a href="#" class="btn btn-secondary">Ver Reportes</a>
            </div>
          </div>
        </div>
        <div class="col-md-4">
          <div class="card">
            <div class="card-body">
              <h5 class="card-title">Configuración</h5>
              <p class="card-text">Ajusta la configuración general del sistema.</p>
              <a href="#" class="btn btn-secondary">Configurar</a>
            </div>
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
