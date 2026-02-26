import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router'; // Import RouterModule for routerLink
import { TokenStorageService } from '../_services/token-storage.service';

@Component({
  selector: 'app-home',
  templateUrl: './home.component.html',
  styleUrls: ['./home.component.css'],
  standalone: true,
  imports: [CommonModule, RouterModule] // Add RouterModule
})
export class HomeComponent implements OnInit {
  private roles: string[] = [];
  isLoggedIn = false;
  showAdminBoard = false;
  showUserManagement = false;
  showTicketAssignment = false;
  showCatalogManagement = false;
  showEntityManagement = false;
  showTechnicianBoard = false;
  showUserBoard = false;
  username?: string;

  constructor(private tokenStorageService: TokenStorageService) { }

  ngOnInit(): void {
    this.isLoggedIn = !!this.tokenStorageService.getToken();

    if (this.isLoggedIn) {
      const user = this.tokenStorageService.getUser();

      if (user) {
        this.roles = user.roles;
        this.username = user.username;

        const isMaster = this.roles.includes('ROLE_ADMIN_MASTER');
        const isTechAdmin = this.roles.includes('ROLE_ADMIN_TECNICOS');
        const isVisualAdmin = this.roles.includes('ROLE_ADMIN_VISUAL');

        this.showAdminBoard = isMaster || isTechAdmin || isVisualAdmin;

        // Granular permissions
        this.showUserManagement = isMaster; // Only MASTER can manage users
        this.showTicketAssignment = isMaster || isTechAdmin;
        this.showCatalogManagement = isMaster || isTechAdmin;
        this.showEntityManagement = isMaster || isTechAdmin;

        this.showTechnicianBoard = this.roles.includes('ROLE_TECNICO');
        this.showUserBoard = this.roles.includes('ROLE_CLIENTE');
      }
    }
  }

  logout(): void {
    this.tokenStorageService.signOut();
    // Redirect to login page after sign out
    window.location.href = '/login';
  }

  toggleSidebar(): void {
    // This script toggles the 'sb-sidenav-toggled' class on the body
    document.body.classList.toggle('sb-sidenav-toggled');
  }
}

