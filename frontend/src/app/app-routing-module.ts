import { NgModule } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';
import { LoginComponent } from './login/login.component';
import { RegisterComponent } from './register/register.component'; // Import RegisterComponent
import { HomeComponent } from './home/home.component';
import { BoardAdminComponent } from './boards/board-admin/board-admin.component';
import { BoardTechnicianComponent } from './boards/board-technician/board-technician.component';
import { BoardUserComponent } from './boards/board-user/board-user.component';
import { ReportIncidentComponent } from './report-incident/report-incident.component'; // New import
import { ProfileComponent } from './profile/profile.component';
import { ChangePasswordComponent } from './change-password/change-password.component'; // Import ChangePasswordComponent
import { AdminDashboardComponent } from './boards/admin-dashboard/admin-dashboard.component'; // Import AdminDashboardComponent
import { ForgotPasswordComponent } from './forgot-password/forgot-password.component';
import { ResetPasswordComponent } from './reset-password/reset-password.component';


const routes: Routes = [
  { path: 'login', component: LoginComponent },
  { path: 'register', component: RegisterComponent }, // Add register route
  { path: 'profile', component: ProfileComponent },
  { path: 'change-password', component: ChangePasswordComponent }, // Add change-password route
  { path: 'forgot-password', component: ForgotPasswordComponent },
  { path: 'reset-password', component: ResetPasswordComponent },
  {
    path: 'home',
    component: HomeComponent,
    runGuardsAndResolvers: 'always',
    children: [
      { path: 'admin', component: AdminDashboardComponent }, // New general admin dashboard
      { path: 'gestion-usuarios', component: BoardAdminComponent }, // User management for admin
      { path: 'tech', component: BoardTechnicianComponent },
      { path: 'user', component: BoardUserComponent },
      { path: 'user/report-incident', component: ReportIncidentComponent }, // New route for reporting
      { path: '', redirectTo: 'user', pathMatch: 'full' }
    ]
  },
  { path: '', redirectTo: 'login', pathMatch: 'full' }
];

@NgModule({
  imports: [RouterModule.forRoot(routes, { onSameUrlNavigation: 'reload' })],
  exports: [RouterModule]
})
export class AppRoutingModule { }
