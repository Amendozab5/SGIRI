import { Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';

export interface NetworkMapData {
    zoneId: number;
    zoneName: string;
    openTickets: number;
    maxPriority: string;
    scoreTickets: number;
    scoreFinal: number;
    level: string;
    dataSource: string;
    latencyOverallMs: number;
    generatedAt: string;
    lastSuccessfulCheckAt: string;
}

@Injectable({
    providedIn: 'root'
})
export class NetworkService {
    private apiUrl = 'http://localhost:8081/api/network';

    constructor(private http: HttpClient) { }

    getNetworkMap(zoneType: string = 'PROVINCIA'): Observable<NetworkMapData[]> {
        let params = new HttpParams().set('zoneType', zoneType);
        return this.http.get<NetworkMapData[]>(`${this.apiUrl}/map`, { params });
    }
}
