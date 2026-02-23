import { Injectable } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http'; // Import HttpHeaders
import { Observable } from 'rxjs';
import { UserProfileResponse } from '../models/user-profile-response.model';
import { UserAdminView } from '../models/user-admin-view.model';
import { UserFormRequest } from '../models/user-form-request.model';
import { TokenStorageService } from './token-storage.service'; // Import TokenStorageService
import { User } from '../models/user.model'; // Import User model

const PROFILE_API_URL = 'http://localhost:8081/api/profile';
const ADMIN_API_URL = 'http://localhost:8081/api/admin';
const DOCS_API_URL = 'http://localhost:8081/api/documents';

@Injectable({
  providedIn: 'root'
})
export class UserService {
  constructor(private http: HttpClient, private tokenStorage: TokenStorageService) { } // Inject TokenStorageService

  getUserProfile(): Observable<UserProfileResponse> { // Revert return type to UserProfileResponse
    return this.http.get<UserProfileResponse>(PROFILE_API_URL);
  }


  // --- Admin User Management ---
  getAllUsers(role?: string): Observable<UserAdminView[]> { // Change return type to UserAdminView[]
    let url = `${ADMIN_API_URL}/users`;
    if (role) {
      url += `?role=${role}`;
    }
    return this.http.get<UserAdminView[]>(url);
  }

  getRoles(): Observable<string[]> {
    return this.http.get<string[]>(`${ADMIN_API_URL}/roles`);
  }

  toggleUserStatus(id: number, estado: string): Observable<any> {
    return this.http.put(`${ADMIN_API_URL}/users/${id}/status`, { estado });
  }

  createUser(user: UserFormRequest): Observable<UserAdminView> { // Change return type to UserAdminView
    return this.http.post<UserAdminView>(`${ADMIN_API_URL}/users`, user);
  }

  updateUser(id: number, user: UserFormRequest): Observable<UserAdminView> { // Change return type to UserAdminView
    return this.http.put<UserAdminView>(`${ADMIN_API_URL}/users/${id}`, user);
  }

  updateUserProfile(nombre: string, apellidos: string, email: string, celular: string): Observable<User> {
    return this.http.put<User>(PROFILE_API_URL, { nombre, apellido: apellidos, email, celular });
  }

  uploadPhoto(file: File): Observable<{ message: string, rutaFoto: string }> {
    const formData: FormData = new FormData();
    formData.append('file', file);
    return this.http.post<{ message: string, rutaFoto: string }>(`${DOCS_API_URL}/upload-photo`, formData);
  }

  deleteUser(id: number): Observable<any> {
    // Note: this method is technically not used anymore as per requirements,
    // but keeping it here for completeness or future use if needed.
    return this.http.delete(`${ADMIN_API_URL}/users/${id}`);
  }
}
