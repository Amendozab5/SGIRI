import { Component, OnInit, ChangeDetectorRef } from '@angular/core';
import { CommonModule, NgIf, NgFor } from '@angular/common';
import { TokenStorageService } from '../_services/token-storage.service';
import { UserService } from '../_services/user.service';
import { User } from '../models/user.model'; // Use the main User model
import { Router } from '@angular/router';
import { FormBuilder, FormGroup, Validators, ReactiveFormsModule } from '@angular/forms'; // Import form modules

@Component({
  selector: 'app-profile',
  templateUrl: './profile.component.html',
  styleUrls: ['./profile.component.css'],
  standalone: true,
  imports: [CommonModule, NgIf, NgFor, ReactiveFormsModule] // Add ReactiveFormsModule
})
export class ProfileComponent implements OnInit {
  currentUser: User | null = null;
  errorMessage = '';
  successMessage = '';
  isLoading = true;
  editMode = false; // New property for edit mode
  isSaving = false; // New property for saving state
  profileForm!: FormGroup; // New FormGroup

  constructor(
    private tokenStorage: TokenStorageService,
    private userService: UserService,
    private router: Router,
    private cd: ChangeDetectorRef,
    private fb: FormBuilder // Inject FormBuilder
  ) { }

  ngOnInit(): void {
    this.loadUserProfile();
    // Initialize form (even in view mode, for structure)
    this.profileForm = this.fb.group({
      nombre: ['', [Validators.required, Validators.minLength(2), Validators.maxLength(50)]],
      apellidos: ['', [Validators.required, Validators.minLength(2), Validators.maxLength(50)]],
      email: ['', [Validators.required, Validators.email, Validators.maxLength(50)]],
      celular: ['', [Validators.required, Validators.pattern('^09[0-9]{8}$')]] // Example for Ecuador: starts with 09, followed by 8 digits
    });
  }

  loadUserProfile(): void {
    this.isLoading = true;
    this.userService.getUserProfile().subscribe({
      next: (data: User) => {
        this.currentUser = data;
        this.isLoading = false;
        this.profileForm.patchValue({
          nombre: this.currentUser.nombre,
          apellidos: this.currentUser.apellidos,
          email: this.currentUser.email,
          celular: this.currentUser.celular
        });
        this.cd.detectChanges();
      },
      error: (err) => {
        this.errorMessage = 'No se pudo cargar la información del usuario. Error: ' + err.status + ' - ' + (err.error?.message || err.message);
        if (err.status === 401 || err.status === 403) {
          this.tokenStorage.signOut();
          this.router.navigate(['/login']);
        }
        this.isLoading = false;
        this.cd.detectChanges();
      }
    });
  }

  toggleEditMode(): void {
    this.editMode = !this.editMode;
    if (this.editMode && this.currentUser) {
      this.profileForm.patchValue({
        nombre: this.currentUser.nombre,
        apellidos: this.currentUser.apellidos,
        email: this.currentUser.email,
        celular: this.currentUser.celular
      });
      this.profileForm.markAsPristine(); // Reset form state
      this.profileForm.markAsUntouched();
    }
    this.errorMessage = ''; // Clear messages when toggling
    this.successMessage = '';
    this.cd.detectChanges();
  }

  cancelEdit(): void {
    this.editMode = false;
    this.errorMessage = '';
    this.successMessage = '';
    if (this.currentUser) {
      this.profileForm.patchValue({ // Reset form to current values
        nombre: this.currentUser.nombre,
        apellidos: this.currentUser.apellidos,
        email: this.currentUser.email,
        celular: this.currentUser.celular
      });
    }
    this.cd.detectChanges();
  }

  saveProfile(): void {
    this.isSaving = true;
    this.errorMessage = '';
    this.successMessage = '';

    if (this.profileForm.invalid) {
      this.profileForm.markAllAsTouched();
      this.isSaving = false;
      this.cd.detectChanges();
      return;
    }

    const { nombre, apellidos, email, celular } = this.profileForm.value;

    this.userService.updateUserProfile(nombre, apellidos, email, celular).subscribe({
      next: (updatedUser: User) => {
        this.currentUser = updatedUser;
        this.tokenStorage.saveUser(this.currentUser); // Update user in storage
        this.editMode = false;
        this.isSaving = false;
        this.successMessage = 'Perfil actualizado exitosamente!';
        this.cd.detectChanges();
      },
      error: (err) => {
        this.errorMessage = err.error?.message || 'Error al actualizar el perfil.';
        this.isSaving = false;
        this.cd.detectChanges();
      }
    });
  }


  uploadPhoto(event: any): void {
    const file = event.target.files[0];
    if (file) {
      this.isSaving = true;
      this.errorMessage = '';
      this.successMessage = '';

      this.userService.uploadPhoto(file).subscribe({
        next: (response: { message: string, rutaFoto: string }) => {
          if (this.currentUser) {
            this.currentUser.rutaFoto = response.rutaFoto;
            this.tokenStorage.saveUser(this.currentUser); // Update user in storage
          }
          this.isSaving = false;
          this.successMessage = response.message || 'Foto de perfil actualizada!';
          this.cd.detectChanges();
        },
        error: (err) => {
          this.errorMessage = err.error?.message || 'Error al subir la foto.';
          this.isSaving = false;
          this.cd.detectChanges();
        }
      });
    }
  }

  getAvatarUrl(): string {
    if (this.currentUser && this.currentUser.rutaFoto) {
      return `http://localhost:8081/uploads/${this.currentUser.rutaFoto}`;
    }
    return '//ssl.gstatic.com/accounts/ui/avatar_2x.png';
  }

  getRoleName(role: string): string {
    if (role === 'ROLE_USER') return 'Usuario';
    if (role === 'ROLE_ADMIN') return 'Administrador';
    if (role === 'ROLE_TECHNICIAN') return 'Técnico';
    return role;
  }

  getRoleClass(role: string): string {
    if (role === 'ROLE_USER') return 'role-USER';
    if (role === 'ROLE_ADMIN') return 'role-ADMIN';
    if (role === 'ROLE_TECHNICIAN') return 'role-TECHNICIAN';
    return '';
  }
}