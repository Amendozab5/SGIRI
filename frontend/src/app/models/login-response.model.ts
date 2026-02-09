export interface LoginResponse {
  id: number;
  username: string;
  email: string;
  roles: string[];
  token: string; // Assuming your token is named accessToken
  primerLogin: boolean;
  // Potentially other basic user info relevant for immediate post-login
}