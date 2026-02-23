export interface UserProfileResponse {
  id: number;
  username: string;
  email: string;
  roles: string[];
  nombre: string;
  apellidos: string;
  cedula: string;
  celular: string;
  idEmpresa?: number;
}
