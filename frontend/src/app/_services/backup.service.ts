import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

const API_URL = 'http://localhost:8081/api/admin/backup';

/**
 * Servicio Angular para invocar el endpoint de backup completo de la base de datos.
 * Solo usuarios con rol ADMIN_MASTER pueden usar este servicio con éxito.
 * El token JWT se adjunta automáticamente por el interceptor HTTP global.
 */
@Injectable({
  providedIn: 'root'
})
export class BackupService {

  constructor(private http: HttpClient) {}

  /**
   * Solicita al backend la generación de un backup completo o de roles.
   * @param type DATABASE | GLOBALS | FULL
   * @param format CUSTOM | PLAIN
   */
  generarBackup(type: string = 'DATABASE', format: string = 'CUSTOM'): Observable<Blob> {
    return this.http.post(`${API_URL}/generar`, {}, {
      params: { type, format },
      responseType: 'blob'
    });
  }

  /**
   * Envía un archivo de backup al servidor para restaurar sobre la base de datos Sandbox.
   * @param file El archivo .dump o .sql subido por el usuario.
   * @param format El formato correspondiente al archivo.
   */
  restaurarBackup(file: File, format: string): Observable<any> {
    const formData = new FormData();
    formData.append('file', file);
    formData.append('format', format);

    return this.http.post(`${API_URL}/restaurar`, formData);
  }
}
