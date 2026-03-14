export interface UserProfileResponse {
  id: number;
  username: string;
  email: string;
  roles: string[];
  nombre: string;
  apellidos: string;
  cedula: string;
  celular: string;
  rutaFoto?: string;
  idEmpresa?: number;
  estado?: string;
  fechaCreacion?: string;
  fechaActualizacion?: string;
  conteoIncidencias?: number;
  nombreArea?: string;
}
