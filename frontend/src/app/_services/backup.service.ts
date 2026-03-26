import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

const API_URL = 'http://localhost:8081/api/admin/backup';

/**
 * Servicio Angular para invocar el endpoint de backup completo de la base de datos.
 * Solo usuarios con rol ADMIN_MASTER pueden usar este servicio con éxito.
 */
@Injectable({
  providedIn: 'root'
})
export class BackupService {

  constructor(private http: HttpClient) {}

  /**
   * Solicita al backend la generación de un backup completo o de roles.
   */
  generarBackup(type: string = 'DATABASE', format: string = 'CUSTOM'): Observable<Blob> {
    return this.http.post(`${API_URL}/generar`, {}, {
      params: { type, format },
      responseType: 'blob'
    });
  }

  /**
   * Envía un archivo de backup al servidor para restaurar sobre la base de datos Sandbox.
   */
  restaurarBackup(file: File, format: string): Observable<any> {
    const formData = new FormData();
    formData.append('file', file);
    formData.append('format', format);
    return this.http.post(`${API_URL}/restaurar`, formData);
  }

  /**
   * Obtiene la configuración actual de los backups automáticos.
   */
  obtenerConfiguracion(): Observable<any> {
    return this.http.get(`${API_URL}/config`);
  }

  /**
   * Actualiza la configuración de automatización de backups.
   */
  guardarConfiguracion(config: any): Observable<any> {
    return this.http.post(`${API_URL}/config`, config);
  }

  /**
   * Obtiene el historial de backups (registros de auditoría).
   */
  obtenerHistorial(): Observable<any[]> {
    return this.http.get<any[]>(`${API_URL}/historial`);
  }

  /**
   * Dispara una ejecución inmediata del flujo de backup completo (ZIP + Cloudinary + Registro BD).
   */
  ejecutarBackupCompletoRemoto(): Observable<any> {
    return this.http.post(`${API_URL}/ejecutar-periodico`, {});
  }

  /**
   * Elimina un archivo de backup que se encuentre en el almacenamiento del servidor.
   */
  eliminarBackupLocal(filename: string): Observable<any> {
    return this.http.delete(`${API_URL}/local/${filename}`);
  }
}
