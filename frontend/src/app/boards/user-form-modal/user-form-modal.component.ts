import { Component, OnInit, Input, Output, EventEmitter, ViewChild, ElementRef, AfterViewInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormBuilder, FormGroup, Validators, ReactiveFormsModule } from '@angular/forms';
import { Modal } from 'bootstrap';
import { UserAdminView } from '../../models/user-admin-view.model';
import { UserFormRequest } from '../../models/user-form-request.model';

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
  private currentUserId: number | null = null;

  constructor(private fb: FormBuilder) {
    this.userForm = this.fb.group({
      username: ['', [Validators.required, Validators.minLength(3), Validators.maxLength(50)]],
      fullName: ['', [Validators.required, Validators.minLength(3), Validators.maxLength(100)]],
      email: ['', [Validators.required, Validators.email, Validators.maxLength(100)]],
      password: ['', [Validators.minLength(6), Validators.maxLength(120)]],
      role: ['', Validators.required],
      estado: ['ACTIVO', Validators.required]
    });
  }

  ngOnInit(): void {}

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
        fullName: user.fullName,
        email: user.email,
        role: user.roles[0],
        estado: user.estado
      });

      this.userForm.get('password')?.clearValidators();
      this.userForm.get('password')?.updateValueAndValidity();
      
      this.userForm.get('username')?.disable();
      this.userForm.get('fullName')?.disable();
      this.userForm.get('email')?.disable();

    } else {
      this.userForm.reset({ estado: 'ACTIVO', fullName: '', email: '' });
      this.userForm.get('password')?.setValidators([
        Validators.required,
        Validators.minLength(6),
        Validators.maxLength(120)
      ]);
      this.userForm.get('password')?.updateValueAndValidity();
      
      this.userForm.get('username')?.enable();
      this.userForm.get('fullName')?.enable();
      this.userForm.get('email')?.enable();
    }
  }

  get f() { return this.userForm.controls; }

  onSubmit(): void {
    if (this.userForm.invalid) {
      this.userForm.markAllAsTouched();
      return;
    }

    const formValue = this.userForm.getRawValue();
    const request: UserFormRequest = {
      username: formValue.username,
      fullName: formValue.fullName,
      email: formValue.email,
      role: formValue.role,
      estado: formValue.estado ? 'ACTIVO' : 'INACTIVO',
    };

    if (!this.isEditMode) {
      request.password = formValue.password;
    }

    this.save.emit({ request, userId: this.currentUserId });
  }

  onCancel(): void {
    this.hide();
  }
}