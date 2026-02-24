import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormBuilder, FormGroup, Validators, ReactiveFormsModule } from '@angular/forms';
import { Router, RouterModule, ActivatedRoute } from '@angular/router';
import { AuthService } from '../_services/auth.service';
import { TokenStorageService } from '../_services/token-storage.service';
import { UserService } from '../_services/user.service'; // Import UserService
import { switchMap, tap, map } from 'rxjs/operators'; // Import switchMap, tap, and map
import { User } from '../models/user.model'; // Import User model
import { LoginResponse } from '../models/login-response.model'; // Import LoginResponse
import { UserProfileResponse } from '../models/user-profile-response.model'; // Import UserProfileResponse

@Component({
  selector: 'app-login',
  templateUrl: './login.component.html',
  styleUrls: ['./login.component.css'],
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, RouterModule]
})
export class LoginComponent implements OnInit {
  loginForm!: FormGroup;
  isLoggedIn = false;
  isLoginFailed = false;
  errorMessage = '';
  roles: string[] = [];
  verificationError = '';
  isLoading = false;

  constructor(
    private fb: FormBuilder,
    private authService: AuthService,
    private tokenStorage: TokenStorageService,
    private router: Router,
    private route: ActivatedRoute,
    private userService: UserService // Inject UserService
  ) { }

  ngOnInit(): void {
    this.loginForm = this.fb.group({
      username: ['', Validators.required],
      password: ['', Validators.required]
    });

    this.route.queryParams.subscribe(params => {
      if (params['error'] === 'verification_failed') {
        this.verificationError = 'La verificación del correo ha fallado. Por favor, intenta registrarte de nuevo o contacta a soporte.';
      }
    });

    if (this.tokenStorage.getToken()) {
      this.isLoggedIn = true;
      // Get the initial user from token storage (might be incomplete)
      const initialUser = this.tokenStorage.getUser();
      if (!initialUser) { // If no user in storage, something went wrong
        this.tokenStorage.signOut();
        this.router.navigate(['/login']);
        return;
      }
      this.roles = initialUser.roles; // Use roles from stored user

      // Fetch the full profile data
      this.userService.getUserProfile().subscribe({
        next: (profileData: UserProfileResponse) => {
          // Merge current stored user with new profile data
          const mergedUser: User = { ...initialUser, ...profileData };
          this.tokenStorage.saveUser(mergedUser); // Save the merged full profile

          // Navigate based on the merged user data
          if (mergedUser.primerLogin) {
            this.router.navigate(['/change-password']);
          } else {
            if (mergedUser.roles.includes('ROLE_ADMIN_MASTER') || mergedUser.roles.includes('ROLE_ADMIN_TECNICOS') || mergedUser.roles.includes('ROLE_ADMIN_VISUAL')) {
              this.router.navigate(['/home/admin']);
            } else if (mergedUser.roles.includes('ROLE_TECNICO')) {
              this.router.navigate(['/home/tech']);
            } else {
              this.router.navigate(['/home/user']);
            }
          }
        },
        error: err => {
          console.error('LoginComponent: Error fetching full profile on init:', err);
          this.tokenStorage.signOut();
          this.router.navigate(['/login']);
        }
      });
    }
  }

  onSubmit(): void {
    if (this.loginForm.invalid) {
      this.loginForm.markAllAsTouched();
      return;
    }

    this.isLoading = true;
    this.isLoginFailed = false;

    const { username, password } = this.loginForm.value;

    this.authService.login({ username, password }).pipe(
      // Save token and initial login response (which has primerLogin and roles)
      tap((loginResponse: LoginResponse) => {
        this.tokenStorage.saveToken(loginResponse.token);
        // Ensure the User object passed to saveUser includes primerLogin and roles
        const userToSave: Partial<User> = {
          id: loginResponse.id,
          username: loginResponse.username,
          email: loginResponse.email,
          roles: loginResponse.roles,
          primerLogin: loginResponse.primerLogin,
          idEmpresa: loginResponse.idEmpresa
        };
        this.tokenStorage.saveUser(userToSave); // Save initial LoginResponse data
      }),
      // Then, fetch the full user profile data
      switchMap(() => this.userService.getUserProfile()),
      // Merge LoginResponse data with UserProfileResponse data to form a complete User object
      map((profileResponse: UserProfileResponse) => {
        const currentStoredUser = this.tokenStorage.getUser(); // Get the user saved by the tap operator
        if (!currentStoredUser) throw new Error('User not found in storage after login.');

        // Merge currentStoredUser (which has roles, primerLogin) with profileResponse (nombre, url)
        const fullUser: User = { ...currentStoredUser, ...profileResponse };
        return fullUser;
      })
    ).subscribe({
      next: (fullUser: User) => {
        this.tokenStorage.saveUser(fullUser); // Save the complete merged User object
        this.isLoggedIn = true;
        this.roles = fullUser.roles;

        if (fullUser.primerLogin) {
          this.router.navigate(['/change-password']);
        } else {
          if (fullUser.roles.includes('ROLE_ADMIN_MASTER') || fullUser.roles.includes('ROLE_ADMIN_TECNICOS') || fullUser.roles.includes('ROLE_ADMIN_VISUAL')) {
            this.router.navigate(['/home/admin']);
          } else if (fullUser.roles.includes('ROLE_TECNICO')) {
            this.router.navigate(['/home/tech']);
          } else {
            this.router.navigate(['/home/user']);
          }
        }
      },
      error: err => {
        this.errorMessage = err.error?.message || 'Login failed! Check your credentials.';
        this.isLoginFailed = true;
        this.isLoading = false;
      }
    });
  }
}