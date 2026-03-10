import { Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';
import { ConfiguracionReporte, TicketResumenReporte, SlaTecnicoReporte, CsatAnalisisReporte, CsatDetalleReporte } from '../models/reporte.model';

const API_URL = 'http://localhost:8081/api/reportes';

@Injectable({
    providedIn: 'root'
})
export class ReporteService {

    constructor(private http: HttpClient) { }

    getDisponibles(): Observable<ConfiguracionReporte[]> {
        return this.http.get<ConfiguracionReporte[]>(`${API_URL}/disponibles`);
    }

    getTicketsResumen(status?: string, search?: string): Observable<TicketResumenReporte[]> {
        let params = new HttpParams();
        if (status && status !== 'TODOS') params = params.set('status', status);
        if (search) params = params.set('search', search);

        return this.http.get<TicketResumenReporte[]>(`${API_URL}/data/tickets-resumen`, { params });
    }

    getSlaTecnico(): Observable<SlaTecnicoReporte[]> {
        return this.http.get<SlaTecnicoReporte[]>(`${API_URL}/data/sla-tecnico`);
    }

    getCsatAnalisis(): Observable<CsatAnalisisReporte[]> {
        return this.http.get<CsatAnalisisReporte[]>(`${API_URL}/data/csat-analisis`);
    }

    exportSlaPdf(): Observable<Blob> {
        return this.http.get(`${API_URL}/export/sla/pdf`, { responseType: 'blob' });
    }

    exportCsatPdf(): Observable<Blob> {
        return this.http.get(`${API_URL}/export/csat/pdf`, { responseType: 'blob' });
    }

    exportTicketsPdf(status?: string, search?: string): Observable<Blob> {
        let params = new HttpParams();
        if (status && status !== 'TODOS') params = params.set('status', status);
        if (search) params = params.set('search', search);

        return this.http.get(`${API_URL}/export/tickets/pdf`, { responseType: 'blob', params });
    }

    exportTicketsExcel(status?: string, search?: string): Observable<Blob> {
        let params = new HttpParams();
        if (status && status !== 'TODOS') params = params.set('status', status);
        if (search) params = params.set('search', search);

        return this.http.get(`${API_URL}/export/tickets/excel`, { responseType: 'blob', params });
    }

    exportSlaExcel(): Observable<Blob> {
        return this.http.get(`${API_URL}/export/sla/excel`, { responseType: 'blob' });
    }

    exportCsatExcel(): Observable<Blob> {
        return this.http.get(`${API_URL}/export/csat/excel`, { responseType: 'blob' });
    }

    getCsatDetalle(): Observable<CsatDetalleReporte[]> {
        return this.http.get<CsatDetalleReporte[]>(`${API_URL}/data/csat-detalle`);
    }
}
