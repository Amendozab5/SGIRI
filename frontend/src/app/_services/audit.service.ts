import { Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';
import { AuditDetail, AuditTimelineResponse } from '../models/audit.model';

const API_URL = 'http://localhost:8081/api/admin/audit';

@Injectable({
  providedIn: 'root'
})
export class AuditService {

  constructor(private http: HttpClient) { }

  getTimeline(filters: any, page: number, size: number): Observable<AuditTimelineResponse> {
    let params = new HttpParams()
      .set('page', page.toString())
      .set('size', size.toString());

    if (filters.startDate) params = params.set('startDate', filters.startDate);
    if (filters.endDate) params = params.set('endDate', filters.endDate);
    if (filters.modulo) params = params.set('modulo', filters.modulo);
    if (filters.accion) params = params.set('accion', filters.accion);
    if (filters.username) params = params.set('username', filters.username);
    if (filters.exito !== undefined && filters.exito !== null && filters.exito !== '') {
        params = params.set('exito', filters.exito);
    }
    if (filters.tabla) params = params.set('tabla', filters.tabla);
    if (filters.idRegistro) params = params.set('idRegistro', filters.idRegistro);

    return this.http.get<AuditTimelineResponse>(`${API_URL}/timeline`, { params });
  }

  getEventDetail(eventKey: string): Observable<AuditDetail> {
    return this.http.get<AuditDetail>(`${API_URL}/timeline/${eventKey}`);
  }
}
