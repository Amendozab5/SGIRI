import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule, Router } from '@angular/router'; // Import RouterModule and Router
import { TokenStorageService } from '../_services/token-storage.service';

@Component({
  selector: 'app-home',
  templateUrl: './home.component.html',
  styleUrls: ['./home.component.css'],
  standalone: true,
  imports: [CommonModule, RouterModule] // Add RouterModule
})
export class HomeComponent implements OnInit {
  public roles: string[] = [];
  isLoggedIn = false;
  showAdminBoard = false;
  showMasterAdminMenu = false;
  showHRMenu = false; // Nuevo: Para ADMIN_CONTRATOS y MASTER
  showTechnicianBoard = false;
  showUserBoard = false; // Added for clarity
  username?: string;

  constructor(
    private tokenStorageService: TokenStorageService,
    private router: Router
  ) { }

  ngOnInit(): void {
    this.isLoggedIn = !!this.tokenStorageService.getToken();

    if (this.isLoggedIn) {
      const user = this.tokenStorageService.getUser();

      if (user) {
        this.roles = user.roles;
        this.username = user.username;

        this.showAdminBoard = this.roles.includes('ROLE_ADMIN') || this.roles.includes('ROLE_ADMIN_MASTER') || this.roles.includes('ROLE_ADMIN_TECNICOS') || this.roles.includes('ROLE_ADMIN_CONTRATOS');
        this.showMasterAdminMenu = this.roles.includes('ROLE_ADMIN') || this.roles.includes('ROLE_ADMIN_MASTER');
        this.showHRMenu = this.showMasterAdminMenu || this.roles.includes('ROLE_ADMIN_CONTRATOS');
        this.showTechnicianBoard = this.roles.includes('ROLE_TECNICO');
        this.showUserBoard = this.roles.includes('ROLE_CLIENTE');

        // Redirección inteligente si están en la raíz de /home
        if (this.router.url === '/home') {
          if (this.roles.includes('ROLE_ADMIN_CONTRATOS')) {
            this.router.navigate(['/home/hr-dashboard']);
          } else if (this.roles.includes('ROLE_ADMIN') || this.roles.includes('ROLE_ADMIN_MASTER') || this.roles.includes('ROLE_ADMIN_TECNICOS')) {
            this.router.navigate(['/home/admin']);
          }
        }
      }
    } else {
      // Not logged in, redirect to login with returnUrl
      this.router.navigate(['/login'], { queryParams: { returnUrl: this.router.url } });
    }
  }

  logout(): void {
    this.tokenStorageService.signOut();
    // Redirect to login page after sign out
    this.router.navigate(['/login']);
  }

  toggleSidebar(): void {
    // This script toggles the 'sb-sidenav-toggled' class on the body
    document.body.classList.toggle('sb-sidenav-toggled');
  }

  navigateToReport(reportCode: string): void {
    this.router.navigate(['/home/reportes'], { queryParams: { report: reportCode } });
  }
}

