import { Component, OnInit, Input, Output, EventEmitter, ViewChild, ElementRef, AfterViewInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormBuilder, FormGroup, Validators, ReactiveFormsModule } from '@angular/forms';
import { Modal } from 'bootstrap';
import { UserAdminView } from '../../models/user-admin-view.model';
import { UserFormRequest } from '../../models/user-form-request.model';
import { MasterDataService } from '../../_services/master-data.service';
import { CatalogoItem } from '../../models/catalogo';

@Component({
  selector: 'app-user-form-modal',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule],
  templateUrl: './user-form-modal.component.html',
  styleUrls: ['./user-form-modal.component.css']
})
export class UserFormModalComponent implements OnInit, AfterViewInit {
  @Input() availableRoles: string[] = [];
  @Output() save = new EventEmitter<{ request: UserFormRequest, userId: number | null }>();
  @Output() closeModal = new EventEmitter<void>();

  @ViewChild('userFormModal') private modalElement!: ElementRef;
  private bootstrapModal!: Modal;

  userForm: FormGroup;
  isEditMode: boolean = false;
  availableStatuses: CatalogoItem[] = [];
  private currentUserId: number | null = null;

  constructor(
    private fb: FormBuilder,
    private masterDataService: MasterDataService
  ) {
    this.userForm = this.fb.group({
      username: ['', [Validators.minLength(3), Validators.maxLength(50)]],
      nombre: ['', [Validators.required, Validators.minLength(3), Validators.maxLength(100)]],
      apellido: ['', [Validators.required, Validators.minLength(3), Validators.maxLength(100)]],
      email: ['', [Validators.required, Validators.email, Validators.maxLength(100)]],
      password: ['', [Validators.minLength(6), Validators.maxLength(120)]],
      role: ['', Validators.required],
      estado: ['ACTIVO', Validators.required],
      cedula: ['', [Validators.pattern('^[0-9]{10}$')]] // Usar cédula para búsqueda/creación
    });
  }

  ngOnInit(): void {
    this.loadStatuses();
  }

  loadStatuses(): void {
    this.masterDataService.getCatalogoItems('ESTADO_USUARIO', true).subscribe({
      next: (items) => {
        this.availableStatuses = items;
      },
      error: (err) => {
        console.error('Error loading user statuses from catalog', err);
      }
    });
  }

  ngAfterViewInit(): void {
    if (this.modalElement) {
      this.bootstrapModal = new Modal(this.modalElement.nativeElement);
    }
  }

  public open(user: UserAdminView | null = null): void {
    this.setupForm(user);
    if (this.bootstrapModal) {
      this.bootstrapModal.show();
    }
  }

  public hide(): void {
    if (this.bootstrapModal) {
      this.bootstrapModal.hide();
    }
    this.closeModal.emit();
  }

  private setupForm(user: UserAdminView | null): void {
    this.isEditMode = !!user;
    this.currentUserId = user ? user.id : null;

    if (this.isEditMode && user) {
      this.userForm.patchValue({
        username: user.username,
        nombre: user.nombre,
        apellido: user.apellido,
        email: user.email,
        role: user.roles && user.roles.length > 0 ? user.roles[0] : '',
        estado: user.estado
      });

      this.userForm.get('password')?.clearValidators();
      this.userForm.get('password')?.updateValueAndValidity();

      this.userForm.get('username')?.disable();
      this.userForm.get('nombre')?.enable();
      this.userForm.get('apellido')?.enable();
      this.userForm.get('email')?.enable();

    } else {
      this.userForm.reset({ estado: 'ACTIVO', fullName: '', email: '' });
      this.userForm.get('password')?.setValidators([
        Validators.required,
        Validators.minLength(6),
        Validators.maxLength(120)
      ]);
      this.userForm.get('password')?.updateValueAndValidity();

      this.userForm.get('username')?.enable();
      this.userForm.get('nombre')?.enable();
      this.userForm.get('apellido')?.enable();
      this.userForm.get('email')?.enable();

      // En modo creación, desactivar validadores de username/password y activar los de metadata
      this.userForm.get('username')?.clearValidators();
      this.userForm.get('password')?.clearValidators();
      this.userForm.get('cedula')?.setValidators([Validators.required, Validators.pattern('^[0-9]{10}$')]);

      this.userForm.get('username')?.updateValueAndValidity();
      this.userForm.get('password')?.updateValueAndValidity();
      this.userForm.get('cedula')?.updateValueAndValidity();
    }
  }

  get f() { return this.userForm.controls; }

  onSubmit(): void {
    if (this.userForm.invalid) {
      this.userForm.markAllAsTouched();
      return;
    }

    const formValue = this.userForm.getRawValue();
    const request: any = { // Usar any temporalmente o actualizar interface
      username: formValue.username,
      nombre: formValue.nombre,
      apellido: formValue.apellido,
      email: formValue.email,
      role: formValue.role,
      estado: formValue.estado,
      cedula: formValue.cedula
    };

    if (!this.isEditMode && formValue.role !== 'CLIENTE' && formValue.role !== 'ROLE_USER') {
      // Opcional: para otros roles que pudieran necesitarlo en el futuro
      if (formValue.password) request.password = formValue.password;
    }

    this.save.emit({ request, userId: this.currentUserId });
  }

  onCancel(): void {
    this.hide();
  }
}