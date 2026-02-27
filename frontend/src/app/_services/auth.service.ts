import { Injectable } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Observable } from 'rxjs';
import { LoginResponse } from '../models/login-response.model'; // Import LoginResponse

const AUTH_API = 'http://localhost:8081/api/auth/';

const httpOptions = {
  headers: new HttpHeaders({ 'Content-Type': 'application/json' })
};

@Injectable({
  providedIn: 'root'
})
export class AuthService {
  constructor(private http: HttpClient) { }

  login(credentials: any): Observable<LoginResponse> { // Change return type to LoginResponse
    return this.http.post<LoginResponse>(AUTH_API + 'login', {
      username: credentials.username,
      password: credentials.password
    }, httpOptions);
  }

  register(user: any): Observable<any> {
    return this.http.post(AUTH_API + 'register', user, httpOptions);
  }

  changePassword(oldPassword: string, newPassword: string): Observable<any> {
    return this.http.post(AUTH_API + 'change-password', {
      oldPassword,
      newPassword
    }, httpOptions);
  }
}
