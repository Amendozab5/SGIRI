import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormBuilder, FormGroup, Validators, ReactiveFormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { AuthService } from '../_services/auth.service';
import { TokenStorageService } from '../_services/token-storage.service';

@Component({
  selector: 'app-change-password',
  templateUrl: './change-password.component.html',
  styleUrls: ['./change-password.component.css'],
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule]
})
export class ChangePasswordComponent implements OnInit {
  passwordForm!: FormGroup;
  isSuccessful = false;
  isChangeFailed = false;
  errorMessage = '';
  isProcessing = false;
  currentUser: any; // Using 'any' for simplicity, could be 'User' model

  constructor(
    private fb: FormBuilder,
    private authService: AuthService,
    private tokenStorage: TokenStorageService,
    private router: Router
  ) { }

  ngOnInit(): void {
    this.currentUser = this.tokenStorage.getUser();
    if (!this.currentUser) {
      this.router.navigate(['/login']); // Redirect if not logged in
      return;
    }

    // We removed the block that prevented users from changing their password freely

    this.passwordForm = this.fb.group({
      oldPassword: ['', Validators.required],
      newPassword: ['', [Validators.required, Validators.minLength(6), Validators.maxLength(40)]],
      confirmNewPassword: ['', Validators.required]
    }, { validators: this.passwordMatchValidator });
  }

  passwordMatchValidator(form: FormGroup) {
    return form.get('newPassword')?.value === form.get('confirmNewPassword')?.value
      ? null : { 'mismatch': true };
  }

  onSubmit(): void {
    if (this.passwordForm.invalid) {
      this.passwordForm.markAllAsTouched();
      return;
    }

    this.isProcessing = true;
    this.isChangeFailed = false;

    const { oldPassword, newPassword } = this.passwordForm.value;

    this.authService.changePassword(oldPassword, newPassword).subscribe({
      next: () => {
        this.isSuccessful = true;
        this.isProcessing = false;
        this.errorMessage = 'Contraseña cambiada exitosamente. Serás redirigido.';
        if (this.currentUser) {
          this.currentUser.primerLogin = false;
        }
        setTimeout(() => {
          if (this.currentUser) {
            this.tokenStorage.saveUser(this.currentUser);
            if (this.currentUser.roles.includes('ROLE_ADMIN_MASTER') || this.currentUser.roles.includes('ROLE_ADMIN_TECNICOS') || this.currentUser.roles.includes('ROLE_ADMIN_VISUAL')) {
              this.router.navigate(['/home/admin']);
            } else if (this.currentUser.roles.includes('ROLE_TECNICO')) {
              this.router.navigate(['/home/tech']);
            } else {
              this.router.navigate(['/home/user']);
            }
          } else {
            this.router.navigate(['/login']);
          }
        }, 1500);
      },
      error: err => {
        console.error('Change Password Error:', err);
        this.errorMessage = err.error?.message || 'Error al cambiar la contraseña.';
        this.isChangeFailed = true;
        this.isProcessing = false;
      }
    });
  }

  get oldPassword() { return this.passwordForm.get('oldPassword'); }
  get newPassword() { return this.passwordForm.get('newPassword'); }
  get confirmNewPassword() { return this.passwordForm.get('confirmNewPassword'); }
}
