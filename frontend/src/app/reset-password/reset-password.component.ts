import { Component, OnInit, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormBuilder, FormGroup, Validators, ReactiveFormsModule } from '@angular/forms';
import { ActivatedRoute, Router, RouterModule } from '@angular/router'; // Import RouterModule
import { AuthService } from '../_services/auth.service';

@Component({
  selector: 'app-reset-password',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, RouterModule], // Add RouterModule here
  templateUrl: './reset-password.component.html',
  styleUrls: ['./reset-password.component.css']
})
export class ResetPasswordComponent implements OnInit {
  resetPasswordForm!: FormGroup;
  token: string | null = null;
  isSuccessful = false;
  isResetFailed = false;
  errorMessage = '';
  isProcessing = false;
  tokenValid = false;
  tokenChecked = false;

  constructor(
    private fb: FormBuilder,
    private route: ActivatedRoute,
    private router: Router,
    private authService: AuthService,
    private cd: ChangeDetectorRef // Inject ChangeDetectorRef
  ) { }

  ngOnInit(): void {
    this.resetPasswordForm = this.fb.group({
      newPassword: ['', [Validators.required, Validators.minLength(6), Validators.maxLength(40)]],
      confirmNewPassword: ['', Validators.required]
    }, { validators: this.passwordMatchValidator });

    this.route.queryParams.subscribe(params => {
      this.token = params['token'];
      if (this.token) {
        this.authService.validateResetToken(this.token).subscribe({
          next: () => {
            this.tokenValid = true;
            this.tokenChecked = true;
            this.cd.detectChanges(); // Force change detection
          },
          error: err => {
            this.errorMessage = err.error?.message || 'El token de restablecimiento es inválido o ha expirado.';
            this.tokenValid = false;
            this.tokenChecked = true;
            this.cd.detectChanges(); // Force change detection
          }
        });
      } else {
        this.tokenValid = false;
        this.tokenChecked = true;
        this.errorMessage = 'No se proporcionó un token para restablecer la contraseña.';
        this.cd.detectChanges(); // Force change detection
      }
    });
  }

  passwordMatchValidator(form: FormGroup) {
    return form.get('newPassword')?.value === form.get('confirmNewPassword')?.value
      ? null : { 'mismatch': true };
  }

  onSubmit(): void {
    if (this.resetPasswordForm.invalid) {
      this.resetPasswordForm.markAllAsTouched();
      return;
    }

    this.isProcessing = true;
    this.isResetFailed = false;

    const { newPassword } = this.resetPasswordForm.value;

    if (this.token && this.tokenValid) {
      this.authService.resetPassword(this.token, newPassword).subscribe({
        next: () => {
          this.isSuccessful = true;
          this.isProcessing = false;
          this.cd.detectChanges(); // Force change detection
          setTimeout(() => {
            this.router.navigate(['/login']);
          }, 3000);
        },
        error: err => {
          this.errorMessage = err.error?.message || 'Error al restablecer la contraseña.';
          this.isResetFailed = true;
          this.isProcessing = false;
          this.cd.detectChanges(); // Force change detection
        }
      });
    } else {
      this.errorMessage = 'Token de restablecimiento de contraseña no encontrado o inválido.';
      this.isResetFailed = true;
      this.isProcessing = false;
      this.cd.detectChanges(); // Force change detection
    }
  }

  get newPassword() { return this.resetPasswordForm.get('newPassword'); }
  get confirmNewPassword() { return this.resetPasswordForm.get('confirmNewPassword'); }
}
