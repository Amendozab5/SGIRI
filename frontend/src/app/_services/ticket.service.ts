import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, of } from 'rxjs';
import { tap } from 'rxjs/operators';
import { TicketRequest } from '../models/ticket-request';
import { Ticket } from '../models/ticket';

const API_URL = 'http://localhost:8081/api/tickets';

@Injectable({
  providedIn: 'root'
})
export class TicketService {
  private techniciansCache: any[] | null = null;
  private lastTechFetch: number = 0;
  private readonly CACHE_TTL = 300000; // 5 minutes

  constructor(private http: HttpClient) { }

  createTicket(ticket: TicketRequest): Observable<any> {
    return this.http.post(API_URL, ticket);
  }

  getMyTickets(): Observable<Ticket[]> {
    return this.http.get<Ticket[]>(API_URL + '/my-tickets');
  }

  getMyTicketsPaged(page: number, size: number, searchTerm?: string, statusId?: number, categoryId?: number): Observable<any> {
    let params = `?page=${page}&size=${size}`;
    if (searchTerm) params += `&searchTerm=${searchTerm}`;
    if (statusId) params += `&statusId=${statusId}`;
    if (categoryId) params += `&categoryId=${categoryId}`;
    return this.http.get<any>(API_URL + '/my-tickets-paged' + params);
  }

  getAllTickets(): Observable<Ticket[]> {
    return this.http.get<Ticket[]>(API_URL + '/all');
  }

  getAssignedTickets(): Observable<Ticket[]> {
    return this.http.get<Ticket[]>(API_URL + '/assigned');
  }

  assignTicket(ticketId: number, userId: number): Observable<any> {
    return this.http.post(API_URL + `/${ticketId}/assign`, { userId });
  }

  getTicketById(id: number): Observable<Ticket> {
    return this.http.get<Ticket>(API_URL + '/' + id);
  }

  addComment(ticketId: number, comentario: string, esInterno: boolean = false): Observable<any> {
    return this.http.post(API_URL + `/${ticketId}/comments`, { comentario, esInterno });
  }

  updateStatus(ticketId: number, statusCode: string, observation: string = ''): Observable<any> {
    return this.http.put(API_URL + `/${ticketId}/status`, { statusCode, observation });
  }

  rateTicket(ticketId: number, puntuacion: number, comentario?: string): Observable<any> {
    return this.http.post(API_URL + `/${ticketId}/rating`, { puntuacion, comentario });
  }

  getTechnicianStats(technicianId: number): Observable<any> {
    return this.http.get(API_URL + `/tecnico/${technicianId}/stats`);
  }

  submitInforme(ticketId: number, informe: any): Observable<any> {
    return this.http.post(API_URL + `/${ticketId}/informe`, informe);
  }

  getInforme(ticketId: number): Observable<any> {
    return this.http.get(API_URL + `/${ticketId}/informe`);
  }

  getFrecuencias(): Observable<any> {
    return this.http.get(API_URL + '/informe/frecuencias');
  }

  downloadPdf(ticketId: number): Observable<Blob> {
    return this.http.get(`${API_URL}/${ticketId}/pdf`, { responseType: 'blob' });
  }

  getAvailableInventario(): Observable<any[]> {
    return this.http.get<any[]>('http://localhost:8081/api/inventario');
  }

  getInventarioUsado(ticketId: number): Observable<any[]> {
    return this.http.get<any[]>(`${API_URL}/${ticketId}/inventario-usado`);
  }

  getTicketsPendingVisit(): Observable<Ticket[]> {
    return this.http.get<Ticket[]>(API_URL + '/pending-visit');
  }

  getDetailedTechnicians(force: boolean = false): Observable<any[]> {
    const now = Date.now();
    if (!force && this.techniciansCache && (now - this.lastTechFetch < this.CACHE_TTL)) {
      return of(this.techniciansCache);
    }
    return this.http.get<any[]>(API_URL + '/tecnicos').pipe(
      tap(data => {
        this.techniciansCache = data;
        this.lastTechFetch = now;
      })
    );
  }

  getTechnicianDocuments(userId: number): Observable<any[]> {
    return this.http.get<any[]>(API_URL + `/tecnicos/${userId}/documentos`);
  }

  assignTicketMultiple(id: number, userIds: number[], groupCode?: string): Observable<any> {
    return this.http.post(API_URL + `/${id}/assign-multiple`, { userIds, groupCode });
  }

  reassignTicket(id: number, userId: number, notaReasignacion: string): Observable<any> {
    return this.http.post(API_URL + `/${id}/reassign`, { userId, notaReasignacion });
  }

  uploadEvidence(file: File): Observable<any> {
    const formData = new FormData();
    formData.append('file', file);
    return this.http.post(`${API_URL}/upload-evidence`, formData);
  }
}