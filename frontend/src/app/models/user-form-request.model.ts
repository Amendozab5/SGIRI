export interface UserFormRequest {
  username: string;
  nombre?: string;
  apellido?: string;
  email?: string; // Added for frontend form type compatibility
  password?: string; // Optional for update
  role: string;
  estado?: string;
  cedula?: string;
  idEmpresa?: number;
}
