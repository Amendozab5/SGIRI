export interface UserFormRequest {
  username: string;
  fullName?: string; // Added for frontend form type compatibility
  email?: string; // Added for frontend form type compatibility
  password?: string; // Optional for update
  role: string;
  estado: string;
}
