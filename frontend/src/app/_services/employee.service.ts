import { Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';
import {
  EmpleadoDTO,
  EmpleadoCreateRequest,
  DocumentoEmpleadoDTO,
  EmpleadoAccessStatusDTO,
  AreaDTO,
  CargoDTO,
  TipoContratoDTO
} from '../models/empleado.model';

const PERSONNEL_API = 'http://localhost:8081/api/personnel';
const DOCS_API      = 'http://localhost:8081/api/documents';
const ORG_API       = 'http://localhost:8081/api/organization';

/** Request DTO for the dedicated employee access endpoint. */
export interface EmpleadoActivarAccesoRequest {
  rol: string;
  idEmpresa?: number | null;
  anioNacimiento?: number;
}

/** Minimal shape returned by GET /api/documents/tipos-documento */
export interface TipoDocumentoDTO {
  id: number;
  codigo: string;
}

@Injectable({ providedIn: 'root' })
export class EmployeeService {
  constructor(private http: HttpClient) {}

  // ── Empleados ──────────────────────────────────────────────────────────────

  /** Lista todos los empleados (para tabla admin) */
  getAll(): Observable<EmpleadoDTO[]> {
    return this.http.get<EmpleadoDTO[]>(`${PERSONNEL_API}/empleados`);
  }

  /** Busca un empleado por cédula */
  getByCedula(cedula: string): Observable<EmpleadoDTO> {
    return this.http.get<EmpleadoDTO>(`${PERSONNEL_API}/empleados/${cedula}`);
  }

  /** Crea el registro laboral de un empleado (y la persona si aún no existe) */
  create(req: EmpleadoCreateRequest): Observable<EmpleadoDTO> {
    return this.http.post<EmpleadoDTO>(`${PERSONNEL_API}/empleados`, req);
  }

  /** Consulta si el empleado está listo para recibir acceso al sistema */
  getAccessStatus(cedula: string): Observable<EmpleadoAccessStatusDTO> {
    return this.http.get<EmpleadoAccessStatusDTO>(
      `${PERSONNEL_API}/empleados/${cedula}/acceso-status`
    );
  }

  /**
   * Activa el acceso al sistema para un empleado existente.
   * Llama al endpoint dedicado POST /api/personnel/empleados/{cedula}/activar-acceso
   * que internamente invoca usuarios.fn_crear_usuario_empleado(...).
   * Las credenciales (username/password) son generadas automáticamente por la función SQL.
   */
  activarAcceso(cedula: string, req: EmpleadoActivarAccesoRequest): Observable<any> {
    return this.http.post<any>(
      `${PERSONNEL_API}/empleados/${cedula}/activar-acceso`,
      req
    );
  }

  // ── Documentos de empleado ─────────────────────────────────────────────────

  /** Lista documentos laborales de un empleado */
  getDocumentos(idEmpleado: number): Observable<DocumentoEmpleadoDTO[]> {
    return this.http.get<DocumentoEmpleadoDTO[]>(`${DOCS_API}/empleado/${idEmpleado}`);
  }

  /** Sube un documento laboral al empleado */
  uploadDocumento(idEmpleado: number, file: File, idTipoDocumento?: number,
    numeroDocumento?: string, descripcion?: string): Observable<DocumentoEmpleadoDTO> {
    const form = new FormData();
    form.append('file', file);
    if (idTipoDocumento != null) form.append('idTipoDocumento', String(idTipoDocumento));
    if (numeroDocumento) form.append('numeroDocumento', numeroDocumento);
    if (descripcion)     form.append('descripcion', descripcion);
    return this.http.post<DocumentoEmpleadoDTO>(
      `${DOCS_API}/empleado/${idEmpleado}/upload`, form
    );
  }

  /** Cambia el estado de un documento (ACTIVO, PENDIENTE, RECHAZADO) */
  cambiarEstadoDocumento(idDocumento: number, estado: string): Observable<DocumentoEmpleadoDTO> {
    return this.http.put<DocumentoEmpleadoDTO>(
      `${DOCS_API}/empleado/docs/${idDocumento}/estado`,
      { estado }
    );
  }

  /** Elimina físicamente un documento del expediente */
  deleteDocumento(idDocumento: number): Observable<any> {
    return this.http.delete(`${DOCS_API}/empleado/docs/${idDocumento}`);
  }

  // ── Catálogos organizacionales (para dropdowns del formulario) ─────────────

  getAreas(): Observable<AreaDTO[]> {
    return this.http.get<AreaDTO[]>(`${ORG_API}/areas`);
  }

  getCargos(): Observable<CargoDTO[]> {
    return this.http.get<CargoDTO[]>(`${ORG_API}/cargos`);
  }

  getTiposContrato(): Observable<TipoContratoDTO[]> {
    return this.http.get<TipoContratoDTO[]>(`${ORG_API}/tipos-contrato`);
  }

  /** Tipos de documento disponibles (excluye FOTO) — para el selector del formulario de subida */
  getTiposDocumento(): Observable<TipoDocumentoDTO[]> {
    return this.http.get<TipoDocumentoDTO[]>(`${DOCS_API}/tipos-documento`);
  }
}
