// This model represents a comprehensive User profile used across the application
export interface User {
  id: number;
  username: string;
  // Personal information (might be derived from Cliente/Empleado)
  cedula?: string;
  nombre?: string;
  apellidos?: string;
  fullName?: string; // Derived field for display purposes
  email: string;
  celular?: string;
  direccion?: string;
  rutaFoto?: string;

  // Roles and status
  roles: string[];
  estado?: string; // ACTIVO / INACTIVO
  primerLogin?: boolean; // Added primerLogin field
  idEmpresa?: number;

  pasaporte?: string;
  sexo?: string;
  fechaNacimiento?: string; // Date represented as string
  nacionalidad?: string;
  aniosResidencia?: number;
  correoPersonal?: string;
  libretaMilitar?: string;
  extensionTelefonica?: string;
  estadoCivil?: string;

  // Audit information
  fechaCreacion?: string; // LocalDateTime from backend
}
