import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { TicketRequest } from '../models/ticket-request';
import { Ticket } from '../models/ticket';

const API_URL = 'http://localhost:8081/api/tickets/';

@Injectable({
  providedIn: 'root'
})
export class TicketService {

  constructor(private http: HttpClient) { }

  createTicket(ticket: TicketRequest): Observable<any> {
    return this.http.post(API_URL, ticket, { responseType: 'text' });
  }

  getMyTickets(): Observable<Ticket[]> {
    return this.http.get<Ticket[]>(API_URL + 'my-tickets');
  }
}