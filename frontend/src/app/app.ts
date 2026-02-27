import { Component, signal, OnInit, OnDestroy, ChangeDetectorRef } from '@angular/core';
import { Subscription } from 'rxjs';
import { TokenStorageService } from './_services/token-storage.service';
import { SharedStateService } from './_services/shared-state.service';
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

  isLoggedIn = false;
  isPasswordChangeRequired = false;
  username?: string;
  avatarUrl: string = '//ssl.gstatic.com/accounts/ui/avatar_2x.png';

  constructor(
    private tokenStorageService: TokenStorageService,
    private sharedState: SharedStateService,
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
  }

  private updateUser(user: User | null): void {
    this.isLoggedIn = !!user;
    if (user) {
      this.username = user.username;
      if (user.rutaFoto) {
        this.avatarUrl = `http://localhost:8081/uploads/${user.rutaFoto}`;
      } else {
        this.avatarUrl = '//ssl.gstatic.com/accounts/ui/avatar_2x.png';
      }
      this.isPasswordChangeRequired = !!user.primerLogin;
      console.log('AppComponent: Password change required:', this.isPasswordChangeRequired);
    } else {
      this.username = undefined;
      this.avatarUrl = '//ssl.gstatic.com/accounts/ui/avatar_2x.png';
      this.isPasswordChangeRequired = false;
      console.log('AppComponent: User logged out.');
    }
    this.cd.detectChanges();
  }

  logout(): void {
    this.tokenStorageService.signOut();
    this.router.navigate(['/login']);
  }

  navigateToProfile(): void {
    this.router.navigate(['/profile']);
  }
}