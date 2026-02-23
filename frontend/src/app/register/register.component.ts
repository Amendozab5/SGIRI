import { Component, OnInit, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormBuilder, FormGroup, Validators, ReactiveFormsModule } from '@angular/forms';
import { RouterModule, Router } from '@angular/router';
import { AuthService } from '../_services/auth.service';
import { CompanyService } from '../_services/company.service';
import { Empresa } from '../models/empresa';

@Component({
  selector: 'app-register',
  templateUrl: './register.component.html',
  styleUrls: ['./register.component.css'],
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, RouterModule]
})
export class RegisterComponent implements OnInit {
  registerForm!: FormGroup;

  isSuccessful = false;
  isSignUpFailed = false;
  message = '';
  isProcessing = false;

  empresas: Empresa[] = [];

  constructor(
    private fb: FormBuilder,
    private authService: AuthService,
    private companyService: CompanyService,
    private router: Router,
    private cdr: ChangeDetectorRef
  ) { }

  ngOnInit(): void {
    this.registerForm = this.fb.group({
      cedula: ['', [Validators.required, Validators.pattern(/^[0-9]{10,13}$/)]],
      idEmpresa: [null, Validators.required]
    });

    this.companyService.getISPs().subscribe({
      next: data => {
        this.empresas = data;
        this.cdr.detectChanges();
      },
      error: err => console.error("Error loading ISPs", err)
    });
  }

  onSubmit(): void {
    if (this.registerForm.invalid) {
      this.registerForm.markAllAsTouched();
      return;
    }

    this.isProcessing = true;
    this.isSignUpFailed = false;

    const requestPayload = {
      cedula: this.registerForm.value.cedula,
      idEmpresa: this.registerForm.value.idEmpresa
    };

    this.authService.register(requestPayload).subscribe({
      next: (res) => {
        console.log("Registro exitoso recibido del servidor:", res);
        this.isSuccessful = true;
        this.isProcessing = false;
        this.message = res.message;
        // Forzamos a Angular a redibujar la pantalla inmediatamente
        this.cdr.detectChanges();
        console.log("Interfaz actualizada forzosamente.");
      },
      error: err => {
        console.error("Error detectado en el registro:", err);
        this.message = err.error?.message || 'El registro falló por un error desconocido.';
        this.isSignUpFailed = true;
        this.isProcessing = false;
      }
    });
  }

  onCancel(): void {
    this.router.navigate(['/login']);
  }
}
