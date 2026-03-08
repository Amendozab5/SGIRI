// Models for the Employee Management module

export interface EmpleadoDTO {
  idEmpleado: number;
  cedula: string;
  nombre: string;
  apellido: string;
  correo?: string;
  celular?: string;
  fechaNacimiento?: string;
  fechaIngreso: string;
  idArea?: number;
  nombreArea?: string;
  idCargo?: number;
  nombreCargo?: string;
  idTipoContrato?: number;
  nombreTipoContrato?: string;
  idSucursal?: number;
  nombreSucursal?: string;
  tieneDocumentoActivo: boolean;
  tieneUsuarioActivo: boolean;
  usernameSistema?: string;
  codigoEstadoUsuario?: string;
}

export interface EmpleadoCreateRequest {
  cedula: string;
  nombre?: string;
  apellido?: string;
  correo?: string;
  celular?: string;
  fechaNacimiento?: string;
  fechaIngreso: string;
  idCargo: number;
  idArea: number;
  idTipoContrato: number;
  idSucursal?: number;
}

export interface DocumentoEmpleadoDTO {
  idDocumento: number;
  numeroDocumento?: string;
  rutaArchivo: string;
  descripcion?: string;
  fechaSubida?: string;
  idTipoDocumento?: number;
  codigoTipoDocumento?: string;
  nombreTipoDocumento?: string;
  idEstado?: number;
  codigoEstado?: string;
  nombreEstado?: string;
  idEmpleado?: number;
  cedulaEmpleado?: string;
}

export interface EmpleadoAccessStatusDTO {
  personaExiste: boolean;
  empleadoExiste: boolean;
  tieneDocumentoActivo: boolean;
  yaTieneUsuario: boolean;
  puedeActivar: boolean;
  usernameExistente?: string;
  codigoEstadoUsuario?: string;
  nombreEstadoUsuario?: string;
  razonBloqueo?: string;
}

export interface AreaDTO { id: number; nombre: string; }
export interface CargoDTO { id: number; nombre: string; }
export interface TipoContratoDTO { id: number; nombre: string; }
