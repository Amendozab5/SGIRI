import { Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';
import { VisitaTecnica, VisitaRequest } from '../models/visita';

const API_URL = 'http://localhost:8081/api/visitas';

@Injectable({
    providedIn: 'root'
})
export class VisitaService {

    constructor(private http: HttpClient) { }

    getVisitas(start: string, end: string): Observable<VisitaTecnica[]> {
        const params = new HttpParams()
            .set('start', start)
            .set('end', end);
        return this.http.get<VisitaTecnica[]>(API_URL, { params });
    }

    getVisitaById(id: number): Observable<VisitaTecnica> {
        return this.http.get<VisitaTecnica>(`${API_URL}/${id}`);
    }

    createVisita(visita: VisitaRequest): Observable<any> {
        return this.http.post(API_URL, visita);
    }

    updateVisita(id: number, visita: VisitaRequest): Observable<any> {
        return this.http.put(`${API_URL}/${id}`, visita);
    }
}
