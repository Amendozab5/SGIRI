import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormBuilder, FormGroup, Validators, ReactiveFormsModule } from '@angular/forms';
import { AuthService } from '../_services/auth.service';
import { RouterModule } from '@angular/router'; // Import RouterModule

@Component({
  selector: 'app-forgot-password',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, RouterModule], // Add RouterModule here
  templateUrl: './forgot-password.component.html',
  styleUrls: ['./forgot-password.component.css']
})
export class ForgotPasswordComponent implements OnInit {
  forgotPasswordForm!: FormGroup;
  isSuccessful = false;
  isRequestFailed = false;
  errorMessage = '';
  isProcessing = false;

  constructor(
    private fb: FormBuilder,
    private authService: AuthService
  ) { }

  ngOnInit(): void {
    this.forgotPasswordForm = this.fb.group({
      email: ['', [Validators.required, Validators.email]]
    });
  }

  onSubmit(): void {
    if (this.forgotPasswordForm.invalid) {
      this.forgotPasswordForm.markAllAsTouched();
      return;
    }

    this.isProcessing = true;
    this.isRequestFailed = false;
    this.isSuccessful = false;

    const { email } = this.forgotPasswordForm.value;

    this.authService.requestPasswordReset(email).subscribe({
      next: () => {
        this.isSuccessful = true;
        this.isProcessing = false;
      },
      error: err => {
        this.errorMessage = err.error?.message || 'Error al solicitar el cambio de contraseña.';
        this.isRequestFailed = true;
        this.isProcessing = false;
      }
    });
  }

  get email() { return this.forgotPasswordForm.get('email'); }
}
