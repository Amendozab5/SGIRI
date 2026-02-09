import { Injectable } from '@angular/core';
import { SharedStateService } from './shared-state.service';
import { User } from '../models/user.model'; // Import User model

const TOKEN_KEY = 'auth-token';
const USER_KEY = 'auth-user';

@Injectable({
  providedIn: 'root'
})
export class TokenStorageService {
  constructor(private sharedState: SharedStateService) { }

  signOut(): void {
    window.sessionStorage.clear();
    this.sharedState.updateUser(null);
  }

  public saveToken(token: string): void {
    window.sessionStorage.removeItem(TOKEN_KEY);
    window.sessionStorage.setItem(TOKEN_KEY, token);
  }

  public getToken(): string | null {
    return window.sessionStorage.getItem(TOKEN_KEY);
  }

  public saveUser(partialUser: Partial<User>): void { // Accept Partial<User>
    let currentUser = this.getUser(); // Get current user from storage

    if (currentUser) {
      // Merge existing user data with new partial data
      currentUser = { ...currentUser, ...partialUser };
    } else {
      // If no current user, just use the partial data (cast to User)
      currentUser = partialUser as User;
    }

    window.sessionStorage.removeItem(USER_KEY);
    window.sessionStorage.setItem(USER_KEY, JSON.stringify(currentUser));
    
    this.sharedState.updateUser(currentUser);
  }

  public getUser(): User | null {
    const user = window.sessionStorage.getItem(USER_KEY);
    if (user) {
      return JSON.parse(user);
    }
    return null;
  }
}
