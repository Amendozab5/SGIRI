import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormBuilder, FormGroup, Validators, ReactiveFormsModule } from '@angular/forms';
import { RouterModule, Router } from '@angular/router';
import { AuthService } from '../_services/auth.service';
import { GeographyService } from '../_services/geography.service';
import { Pais } from '../models/pais';
import { Ciudad } from '../models/ciudad';
import { Canton } from '../models/canton';
import { of } from 'rxjs';
import { switchMap } from 'rxjs/operators';

@Component({
  selector: 'app-register',
  templateUrl: './register.component.html',
  styleUrls: ['./register.component.css'],
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, RouterModule]
})
export class RegisterComponent implements OnInit {
  registerForm!: FormGroup;
  
  paises: Pais[] = [];
  ciudades: Ciudad[] = [];
  cantones: Canton[] = [];

  isSuccessful = false;
  isSignUpFailed = false;
  errorMessage = '';
  isProcessing = false;

  constructor(
    private fb: FormBuilder,
    private authService: AuthService,
    private geographyService: GeographyService,
    private router: Router
  ) { }

  ngOnInit(): void {
    this.registerForm = this.fb.group({
      personalInfo: this.fb.group({
        nombres: ['', [Validators.required, Validators.minLength(3)]],
        apellidos: ['', [Validators.required, Validators.minLength(3)]],
        cedula: ['', [Validators.required, Validators.pattern(/^[0-9]{10}$/)]]
      }),
      contactInfo: this.fb.group({
        direccion: ['', [Validators.required, Validators.maxLength(200)]],
        numeroTelefonico: ['', [Validators.required, Validators.pattern(/^\+?[0-9]{7,15}$/)]],
        email: ['', [Validators.required, Validators.email]]
      }),
      location: this.fb.group({
        paisId: [null, Validators.required],
        ciudadId: [{ value: null, disabled: true }, Validators.required],
        cantonId: [{ value: null, disabled: true }, Validators.required]
      })
    });

    this.geographyService.getPaises().subscribe(data => this.paises = data);

    // Initial setup for cascading dropdowns
    this.setupLocationDropdowns();
  }

  get personalInfo() { return this.registerForm.get('personalInfo') as FormGroup; }
  get contactInfo() { return this.registerForm.get('contactInfo') as FormGroup; }
  get location() { return this.registerForm.get('location') as FormGroup; }

  private setupLocationDropdowns(): void {
    // Subscribe to paisId changes
    this.location.get('paisId')?.valueChanges
      .pipe(
        switchMap(paisId => {
          this.ciudades = [];
          this.cantones = [];
          this.location.get('ciudadId')?.reset({ value: null, disabled: true });
          this.location.get('cantonId')?.reset({ value: null, disabled: true });

          if (paisId) {
            this.location.get('ciudadId')?.enable();
            return this.geographyService.getCiudades(paisId);
          }
          return of([]);
        })
      )
      .subscribe(data => this.ciudades = data);

    // Subscribe to ciudadId changes
    this.location.get('ciudadId')?.valueChanges
      .pipe(
        switchMap(ciudadId => {
          this.cantones = [];
          this.location.get('cantonId')?.reset({ value: null, disabled: true });

          if (ciudadId) {
            this.location.get('cantonId')?.enable();
            return this.geographyService.getCantones(ciudadId);
          }
          return of([]);
        })
      )
      .subscribe(data => this.cantones = data);
  }

  onSubmit(): void {
    if (this.registerForm.invalid) {
      this.registerForm.markAllAsTouched();
      return;
    }

    this.isProcessing = true;
    this.isSignUpFailed = false;

    const personal = this.personalInfo.value;
    const contact = this.contactInfo.value;
    const loc = this.location.value;

    const requestPayload = {
      nombres: personal.nombres.trim(),
      apellidos: personal.apellidos.trim(),
      cedula: personal.cedula,
      direccion: contact.direccion.trim(),
      numeroTelefonico: contact.numeroTelefonico,
      email: contact.email.trim(),
      idCanton: loc.cantonId,
    };

    this.authService.register(requestPayload).subscribe({
      next: () => {
        this.isSuccessful = true;
        this.isProcessing = false;
        setTimeout(() => {
          this.router.navigate(['/login']);
        }, 3000);
      },
      error: err => {
        console.error("Error during registration:", err);
        this.errorMessage = err.error?.message || 'El registro falló por un error desconocido.';
        this.isSignUpFailed = true;
        this.isProcessing = false;
        console.log("errorMessage after setting:", this.errorMessage);
        console.log("isSignUpFailed after setting:", this.isSignUpFailed);
      }
    });
  }

  onCancel(): void {
    this.router.navigate(['/login']);
  }
}