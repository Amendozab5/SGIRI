import { NgModule } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';
import { LoginComponent } from './login/login.component';
import { RegisterComponent } from './register/register.component'; // Import RegisterComponent
import { HomeComponent } from './home/home.component';
import { BoardAdminComponent } from './boards/board-admin/board-admin.component';
import { CatalogManagementComponent } from './boards/catalog-management/catalog-management.component'; // Import New Component
import { EntityManagementComponent } from './boards/entity-management/entity-management.component'; // Import New Component
import { BoardTechnicianComponent } from './boards/board-technician/board-technician.component';
import { BoardUserComponent } from './boards/board-user/board-user.component';
import { ReportIncidentComponent } from './report-incident/report-incident.component'; // New import
import { ProfileComponent } from './profile/profile.component';
import { ChangePasswordComponent } from './change-password/change-password.component'; // Import ChangePasswordComponent
import { AdminDashboardComponent } from './boards/admin-dashboard/admin-dashboard.component'; // Import AdminDashboardComponent
import { TicketDetailComponent } from './boards/ticket-detail/ticket-detail.component'; // Import New Component
import { TicketAssignmentComponent } from './boards/ticket-assignment/ticket-assignment.component'; // Import New Component
import { EmployeeManagementComponent } from './boards/employee-management/employee-management.component';
import { TechDashboardComponent } from './boards/tech-dashboard/tech-dashboard.component'; // Import TechDashboardComponent
import { TicketAssignPanelComponent } from './boards/ticket-assign-panel/ticket-assign-panel.component';
import { HrDashboardComponent } from './boards/hr-dashboard/hr-dashboard.component';
import { TechPerformanceComponent } from './boards/tech-performance/tech-performance.component';


import { AuditManagementComponent } from './boards/audit-management/audit-management.component'; // New import
import { ReportsBoardComponent } from './boards/reports-board/reports-board.component';

export const routes: Routes = [
  { path: 'login', component: LoginComponent },
  { path: 'register', component: RegisterComponent }, // Add register route
  { path: 'profile', component: ProfileComponent },
  { path: 'change-password', component: ChangePasswordComponent }, // Add change-password route
  {
    path: 'home',
    component: HomeComponent,
    runGuardsAndResolvers: 'always',
    children: [
      { path: 'admin', component: AdminDashboardComponent }, // New general admin dashboard
      { path: 'hr-dashboard', component: HrDashboardComponent }, // Nuevo dashboard para contratos
      { path: 'gestion-usuarios', component: BoardAdminComponent }, // User management for admin
      { path: 'gestion-empleados', component: EmployeeManagementComponent }, // Employee management
      { path: 'gestion-catalogos', component: CatalogManagementComponent }, // Catalog management
      { path: 'gestion-entidades', component: EntityManagementComponent }, // Entity management
      { path: 'gestion-auditoria', component: AuditManagementComponent }, // New audit route
      { path: 'reportes', component: ReportsBoardComponent }, // New reports route
      { path: 'tech', component: TechDashboardComponent }, // Technician dashboard
      { path: 'tech-tickets', component: BoardTechnicianComponent }, // Technician tickets list
      { path: 'tech-stats', component: TechPerformanceComponent }, // New Tech Performance route
      { path: 'asignacion-tickets', component: TicketAssignmentComponent },
      { path: 'user', component: BoardUserComponent },
      { path: 'user/report-incident', component: ReportIncidentComponent }, // New route for reporting
      { path: 'user/ticket/:id', component: TicketDetailComponent }, // New route for detail
      { path: 'admin/tickets/asignar/:id', component: TicketAssignPanelComponent },
      { path: 'network-map', loadComponent: () => import('./boards/network-map/network-map.component').then(m => m.NetworkMapComponent) },
      { path: 'agenda', loadComponent: () => import('./boards/scheduler/scheduler.component').then(m => m.SchedulerComponent) },
      { path: '', redirectTo: 'user', pathMatch: 'full' }
    ]
  },
  { path: '', redirectTo: 'login', pathMatch: 'full' }
];
