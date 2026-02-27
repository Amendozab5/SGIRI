import { Component, OnInit, ChangeDetectorRef, ViewChild } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormControl, ReactiveFormsModule, FormsModule } from '@angular/forms';
import { debounceTime, distinctUntilChanged, map, startWith } from 'rxjs/operators';
import { Observable, BehaviorSubject, combineLatest } from 'rxjs';
import { Modal } from 'bootstrap';

import { UserService } from '../../_services/user.service';
import { UserAdminView } from '../../models/user-admin-view.model';
import { UserFormRequest } from '../../models/user-form-request.model';
import { UserFormModalComponent } from '../user-form-modal/user-form-modal.component';
import { MasterDataService } from '../../_services/master-data.service';
import { CatalogoItem } from '../../models/catalogo';

@Component({
  selector: 'app-board-admin',
  templateUrl: './board-admin.component.html',
  styleUrls: ['./board-admin.component.css'],
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, FormsModule, UserFormModalComponent]
})
export class BoardAdminComponent implements OnInit {
  private users$ = new BehaviorSubject<UserAdminView[]>([]);
  filteredUsers$!: Observable<UserAdminView[]>;
  searchControl = new FormControl('');
  isLoading = false;

  availableRoles: string[] = [];
  selectedRoleFilter: string = 'all';
  private roleFilter$ = new BehaviorSubject<string>('all');

  availableStatuses: any[] = [];
  userToToggleStatus: UserAdminView | undefined;
  private toggleStatusModal: Modal | undefined;
  @ViewChild('toggleStatusUserModal') toggleStatusUserModalElement: any;

  userToDelete: UserAdminView | undefined;
  private deleteModal: Modal | undefined;
  @ViewChild('deleteUserModal') deleteUserModalElement: any;

  @ViewChild(UserFormModalComponent) userFormModalComponent!: UserFormModalComponent;

  constructor(
    private userService: UserService,
    private masterDataService: MasterDataService,
    private cdr: ChangeDetectorRef
  ) { }

  ngOnInit(): void {
    this.isLoading = true;

    this.userService.getAllUsers().subscribe({
      next: (data: UserAdminView[]) => {
        this.users$.next(data);
        this.isLoading = false;
        this.cdr.detectChanges();
      },
      error: (err) => {
        console.error(err);
        this.isLoading = false;
      }
    });

    this.userService.getRoles().subscribe({
      next: (roles: string[]) => {
        this.availableRoles = roles;
      },
      error: (err) => {
        console.error('Error fetching roles', err);
      }
    });

    this.masterDataService.getCatalogoItems('ESTADO_USUARIO', true).subscribe({
      next: (items: CatalogoItem[]) => {
        this.availableStatuses = items;
      },
      error: (err) => {
        console.error('Error fetching user statuses', err);
      }
    });

    const searchTerm$ = this.searchControl.valueChanges.pipe(
      startWith(''),
      debounceTime(300),
      distinctUntilChanged()
    );

    this.filteredUsers$ = combineLatest([this.users$, searchTerm$, this.roleFilter$]).pipe(
      map(([users, term, roleFilter]) => this.filterUsers(users, term, roleFilter))
    );
  }

  ngAfterViewInit(): void {
    if (this.toggleStatusUserModalElement) {
      this.toggleStatusModal = new Modal(this.toggleStatusUserModalElement.nativeElement);
    }
    if (this.deleteUserModalElement) {
      this.deleteModal = new Modal(this.deleteUserModalElement.nativeElement);
    }
  }

  filterByRole(role: string): void {
    this.selectedRoleFilter = role;
    this.roleFilter$.next(role);
  }

  private filterUsers(users: UserAdminView[], term: string | null, roleFilter: string): UserAdminView[] {
    let filtered = users.slice();

    if (term) {
      const lowerCaseTerm = term.toLowerCase();
      filtered = filtered.filter(user =>
        (user.username?.toLowerCase().includes(lowerCaseTerm) || false) ||
        (user.fullName?.toLowerCase().includes(lowerCaseTerm) || false) ||
        (user.email?.toLowerCase().includes(lowerCaseTerm) || false) ||
        (user.roles?.some(role => role.toLowerCase().includes(lowerCaseTerm)) || false)
      );
    }

    if (roleFilter && roleFilter !== 'all') {
      filtered = filtered.filter(user => user.roles.includes(roleFilter));
    }

    return filtered;
  }

  isStatusAvailable(codigo: string): boolean {
    return this.availableStatuses.some(status => status.codigo === codigo);
  }

  openToggleStatusModal(user: UserAdminView): void {
    this.userToToggleStatus = user;
    if (this.toggleStatusModal) {
      this.toggleStatusModal.show();
    }
  }

  confirmToggleStatus(): void {
    if (!this.userToToggleStatus) return;

    const newStatus = this.userToToggleStatus.estado === 'ACTIVO' ? 'INACTIVO' : 'ACTIVO';

    if (!this.isStatusAvailable(newStatus)) {
      alert(`El estado '${newStatus}' no está disponible actualmente en el catálogo.`);
      return;
    }

    this.userService.toggleUserStatus(this.userToToggleStatus.id, newStatus).subscribe({
      next: () => {
        const currentUsers = this.users$.getValue();
        const updatedUsers = currentUsers.map(u =>
          u.id === this.userToToggleStatus?.id ? { ...u, estado: newStatus } : u
        );
        this.users$.next(updatedUsers);
        this.closeToggleStatusModal();
      },
      error: (err) => {
        console.error('Error toggling user status', err);
        this.closeToggleStatusModal();
      }
    });
  }

  closeToggleStatusModal(): void {
    if (this.toggleStatusModal) {
      this.toggleStatusModal.hide();
    }
  }

  openDeleteConfirmModal(user: UserAdminView): void {
    this.userToDelete = user;
    this.deleteModal?.show();
  }

  closeDeleteConfirmModal(): void {
    this.deleteModal?.hide();
  }

  confirmDelete(): void {
    if (!this.userToDelete) return;

    this.userService.deleteUser(this.userToDelete.id).subscribe({
      next: () => {
        const currentUsers = this.users$.getValue();
        const updatedUsers = currentUsers.filter(u => u.id !== this.userToDelete?.id);
        this.users$.next(updatedUsers);
        this.closeDeleteConfirmModal();
      },
      error: (err) => {
        console.error('Error deleting user', err);
        this.closeDeleteConfirmModal();
      }
    });
  }

  openCreateUserModal(): void {
    this.userFormModalComponent.open();
  }

  openEditUserModal(user: UserAdminView): void {
    this.userFormModalComponent.open(user);
  }

  onUserFormSave({ request, userId }: { request: UserFormRequest, userId: number | null }): void {
    this.isLoading = true;
    if (userId) { // Edit mode
      this.userService.updateUser(userId, request).subscribe({
        next: (updatedUser: UserAdminView) => {
          const currentUsers = this.users$.getValue();
          const newUsers = currentUsers.map(u => u.id === updatedUser.id ? updatedUser : u);
          this.users$.next(newUsers);
          this.userFormModalComponent.hide(); // Hide the modal directly after save
          this.isLoading = false;
        },
        error: (err) => {
          console.error('Error updating user', err);
          this.isLoading = false;
        }
      });
    } else { // Create mode
      this.userService.createUser(request).subscribe({
        next: (newUser: UserAdminView) => {
          const currentUsers = this.users$.getValue();
          this.users$.next([...currentUsers, newUser]);
          this.userFormModalComponent.hide(); // Hide the modal directly after save
          this.isLoading = false;
        },
        error: (err) => {
          console.error('Error creating user', err);
          this.isLoading = false;
        }
      });
    }
  }

  // Method to handle actions after the UserFormModalComponent is closed
  onUserFormModalClosed(): void {
    // Perform any cleanup or data refresh needed after the modal is closed
    // For example, if you need to reload all users:
    // this.loadAllUsers(); 
    // In this case, onUserFormSave already updates the list, so no further action is strictly necessary here for data refresh
  }
}
