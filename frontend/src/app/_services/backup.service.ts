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
   * Solicita al backend la generación de un backup completo y retorna el archivo
   * como Blob para ser descargado directamente en el navegador.
   */
  generarBackup(): Observable<Blob> {
    return this.http.post(`${API_URL}/generar`, {}, {
      responseType: 'blob'
    });
  }
}
