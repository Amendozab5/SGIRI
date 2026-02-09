// This model reflects the UserAdminView DTO from the backend for the admin panel
export interface UserAdminView {
  id: number;
  username: string;
  fullName: string;
  email: string;
  roles: string[];
  estado: string;
  lastLogin?: string | null; // It's LocalDateTime in backend, but will be string in JSON, and can be null
  fechaCreacion: string; // LocalDateTime in backend, string in JSON
}