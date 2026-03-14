import { Component, OnInit, ChangeDetectorRef } from '@angular/core';
import { CommonModule, NgIf, NgFor } from '@angular/common';
import { TokenStorageService } from '../_services/token-storage.service';
import { UserService } from '../_services/user.service';
import { User } from '../models/user.model'; // Use the main User model
import { Router } from '@angular/router';
import { FormBuilder, FormGroup, Validators, ReactiveFormsModule } from '@angular/forms';
import { TicketService } from '../_services/ticket.service';
import { CompanyService } from '../_services/company.service';
import { forkJoin, map } from 'rxjs';

@Component({
  selector: 'app-profile',
  templateUrl: './profile.component.html',
  styleUrls: ['./profile.component.css'],
  standalone: true,
  imports: [CommonModule, NgIf, ReactiveFormsModule] // Add ReactiveFormsModule
})
export class ProfileComponent implements OnInit {
  currentUser: User | null = null;
  errorMessage = '';
  successMessage = '';
  isLoading = true;
  editMode = false; // New property for edit mode
  isSaving = false; // New property for saving state
  profileForm!: FormGroup; // New FormGroup
  
  // Role stats
  userStats = { total: 0, open: 0, closed: 0 };
  techStats = { assigned: 0, inProgress: 0, resolved: 0 };
  adminStats = { totalTickets: 0, pendingVisits: 0, csatAvg: 0 };
  companyName = 'No asignada';
  isUser = false;
  isTech = false;
  isAdmin = false;
  
  // Technician Evaluation Data
  techEvaluation = {
    avgRating: 0,
    totalEvaluations: 0,
    totalAtendidas: 0,
    responseTimeRating: 4.8, // Default mocks since they aren't in backend yet
    qualityRating: 4.7,
    courtesyRating: 4.9,
    recentComments: [] as any[]
  };

  constructor(
    private tokenStorage: TokenStorageService,
    private userService: UserService,
    private router: Router,
    private cd: ChangeDetectorRef,
    private fb: FormBuilder,
    private ticketService: TicketService,
    private companyService: CompanyService
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
        
        this.checkRoles();
        this.fetchRoleSpecificData();
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
      if (this.currentUser.rutaFoto.startsWith('http')) {
        return this.currentUser.rutaFoto;
      }
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
    if (role === 'ROLE_ADMIN' || role === 'ROLE_ADMIN_MASTER') return 'role-ADMIN';
    if (role === 'ROLE_TECHNICIAN' || role === 'ROLE_TECNICO') return 'role-TECHNICIAN';
    return '';
  }

  private checkRoles(): void {
    if (!this.currentUser) return;
    const roles = this.currentUser.roles;
    this.isTech = roles.some(r => r.includes('TECHNICIAN') || r.includes('TECNICO'));
    this.isUser = roles.some(r => r.includes('USER') || r.includes('CLIENTE'));
    this.isAdmin = roles.some(r => r.includes('ADMIN'));
  }

  private fetchRoleSpecificData(): void {
    if (!this.currentUser) return;

    // Fetch Company Name if exists
    if (this.currentUser.idEmpresa) {
      this.companyService.getISPs().subscribe(isps => {
        const company = isps.find(i => i.id === this.currentUser?.idEmpresa);
        if (company) this.companyName = company.nombreComercial;
      });
    }

    if (this.isTech) {
      this.ticketService.getAssignedTickets().subscribe(tickets => {
        this.techStats.assigned = tickets.length;
        this.techStats.inProgress = tickets.filter(t => t.estadoItem?.codigo === 'EN_PROGRESO').length;
        this.techStats.resolved = tickets.filter(t => t.estadoItem?.codigo === 'RESUELTO').length;
        
        // Extract recent feedback comments
        this.techEvaluation.recentComments = tickets
          .filter(t => t.calificacionSatisfaccion && t.comentarioCalificacion)
          .sort((a, b) => new Date(b.fechaCierre!).getTime() - new Date(a.fechaCierre!).getTime())
          .slice(0, 3)
          .map(t => t.comentarioCalificacion);

        this.cd.detectChanges();
      });

      // Fetch dynamic stats from backend
      this.ticketService.getTechnicianStats(this.currentUser.id).subscribe(stats => {
        this.techEvaluation.avgRating = stats.promedio;
        this.techEvaluation.totalEvaluations = stats.totalCalificados;
        this.techEvaluation.totalAtendidas = stats.totalTickets;
        
        // Simulating specific ratings based on general average for visual harmony
        // In a real scenario, these would come from specialized columns
        this.techEvaluation.responseTimeRating = Number((stats.promedio * 0.95).toFixed(1));
        this.techEvaluation.qualityRating = Number((stats.promedio * 1.02).toFixed(1));
        this.techEvaluation.courtesyRating = Number((stats.promedio * 0.98).toFixed(1));
        
        this.cd.detectChanges();
      });
    } else if (this.isUser) {
      this.ticketService.getMyTickets().subscribe(tickets => {
        this.userStats.total = tickets.length;
        this.userStats.open = tickets.filter(t => t.estadoItem?.codigo !== 'CERRADO' && t.estadoItem?.codigo !== 'RESUELTO').length;
        this.userStats.closed = tickets.filter(t => t.estadoItem?.codigo === 'CERRADO').length;
        this.cd.detectChanges();
      });
    }

    if (this.isAdmin) {
      // Proposing stats for admin: General system health
      forkJoin({
        pending: this.ticketService.getTicketsPendingVisit(),
        all: this.ticketService.getAllTickets()
      }).subscribe(({ pending, all }) => {
        this.adminStats.totalTickets = all.length;
        this.adminStats.pendingVisits = pending.length;
        // Mocking CSAT since a general avg might need a specific endpoint
        this.adminStats.csatAvg = 4.8; 
        this.cd.detectChanges();
      });
    }
  }
}