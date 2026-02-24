import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { TicketRequest } from '../models/ticket-request';
import { Ticket } from '../models/ticket';

const API_URL = 'http://localhost:8081/api/tickets';

@Injectable({
  providedIn: 'root'
})
export class TicketService {

  constructor(private http: HttpClient) { }

  createTicket(ticket: TicketRequest): Observable<any> {
    return this.http.post(API_URL, ticket);
  }

  getMyTickets(): Observable<Ticket[]> {
    return this.http.get<Ticket[]>(API_URL + '/my-tickets');
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
}