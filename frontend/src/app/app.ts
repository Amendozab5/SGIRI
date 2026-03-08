import { Component, signal, OnInit, OnDestroy, ChangeDetectorRef } from '@angular/core';
import { Subscription, interval } from 'rxjs';
import { TokenStorageService } from './_services/token-storage.service';
import { AuthService } from './_services/auth.service';
import { SharedStateService } from './_services/shared-state.service';
import { NotificationService } from './_services/notification.service';
import { NotificacionWeb } from './models/notification';
import { User } from './models/user.model';
import { Router, RouterModule } from '@angular/router'; // Import RouterModule
import { BootstrapDropdownDirective } from './bootstrap-dropdown.directive'; // Import the new directive
import { CommonModule } from '@angular/common'; // Import CommonModule for NgIf

@Component({
  selector: 'app-root',
  templateUrl: './app.html',
  standalone: true,
  styleUrl: './app.css',
  imports: [CommonModule, RouterModule, BootstrapDropdownDirective] // Add RouterModule
})
export class App implements OnInit, OnDestroy {
  protected readonly title = signal('frontend');
  private userSubscription!: Subscription;
  private pollingSubscription?: Subscription;

  isLoggedIn = false;
  isPasswordChangeRequired = false;
  username?: string;
  avatarUrl: string = '//ssl.gstatic.com/accounts/ui/avatar_2x.png';

  // Notificaciones
  notificaciones: NotificacionWeb[] = [];
  unreadCount = 0;

  constructor(
    private tokenStorageService: TokenStorageService,
    private sharedState: SharedStateService,
    private notificationService: NotificationService,
    private authService: AuthService,
    private router: Router,
    private cd: ChangeDetectorRef
  ) { }

  ngOnInit(): void {
    this.userSubscription = this.sharedState.currentUser$.subscribe(user => {
      this.updateUser(user);
    });
  }

  ngOnDestroy(): void {
    if (this.userSubscription) {
      this.userSubscription.unsubscribe();
    }
    if (this.pollingSubscription) {
      this.pollingSubscription.unsubscribe();
    }
  }

  private startPolling(): void {
    if (this.pollingSubscription) return;
    this.loadNotifications();
    this.pollingSubscription = interval(30000).subscribe(() => {
      this.loadNotifications();
    });
  }

  private stopPolling(): void {
    if (this.pollingSubscription) {
      this.pollingSubscription.unsubscribe();
      this.pollingSubscription = undefined;
    }
  }

  loadNotifications(): void {
    if (!this.isLoggedIn) return;

    this.notificationService.getUnreadCount().subscribe(res => {
      this.unreadCount = res.unreadCount;
      this.cd.detectChanges();
    });

    this.notificationService.getMisNotificaciones().subscribe(notis => {
      this.notificaciones = notis;
      this.cd.detectChanges();
    });
  }

  handleNotificationClick(noti: NotificacionWeb): void {
    if (!noti.leida) {
      this.notificationService.marcarComoLeida(noti.id).subscribe(() => {
        this.loadNotifications();
      });
    }

    let targetUrl = noti.rutaRedireccion;

    // --- REPARACIÓN DE RUTAS ANTIGUAS/QUEMADAS ---
    // Si la ruta viene del sistema viejo, la mapeamos al nuevo sistema de /home/user/ticket/:id
    if (targetUrl.includes('/cliente/tickets/detalle/')) {
      targetUrl = targetUrl.replace('/cliente/tickets/detalle/', '/home/user/ticket/');
    } else if (targetUrl.includes('/tecnico/tickets/detalle/')) {
      targetUrl = targetUrl.replace('/tecnico/tickets/detalle/', '/home/user/ticket/');
    }

    this.router.navigateByUrl(targetUrl);
  }

  markAllAsRead(): void {
    this.notificationService.marcarTodasComoLeidas().subscribe(() => {
      this.loadNotifications();
    });
  }

  private updateUser(user: User | null): void {
    this.isLoggedIn = !!user;
    if (user) {
      this.username = user.username;

      // Avatar
      this.avatarUrl = user.rutaFoto ? `http://localhost:8081/uploads/${user.rutaFoto}` : '//ssl.gstatic.com/accounts/ui/avatar_2x.png';

      this.isPasswordChangeRequired = !!user.primerLogin;
      this.startPolling();
    } else {
      this.username = undefined;
      this.stopPolling();
      this.notificaciones = [];
      this.unreadCount = 0;
    }
    this.cd.detectChanges();
  }

  logout(): void {
    this.authService.logout().subscribe({
      next: () => {
        this.tokenStorageService.signOut();
        this.router.navigate(['/login']);
      },
      error: (err) => {
        console.error('Error en logout auditado:', err);
        // Fallback: cerrar sesión local aunque falle la auditoría de red
        this.tokenStorageService.signOut();
        this.router.navigate(['/login']);
      }
    });
  }

  navigateToProfile(): void {
    this.router.navigate(['/profile']);
  }
}