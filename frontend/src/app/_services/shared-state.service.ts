import { Injectable } from '@angular/core';
import { BehaviorSubject } from 'rxjs';
import { User } from '../models/user.model';

const USER_KEY = 'auth-user';

@Injectable({
  providedIn: 'root'
})
export class SharedStateService {
  private currentUserSubject: BehaviorSubject<User | null>;

  constructor() {
    const user = window.sessionStorage.getItem(USER_KEY);
    this.currentUserSubject = new BehaviorSubject<User | null>(user ? JSON.parse(user) : null);
  }

  get currentUser$() {
    return this.currentUserSubject.asObservable();
  }

  updateUser(user: User | null) {
    this.currentUserSubject.next(user);
  }
}