import { Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable, BehaviorSubject, timer, Subscription } from 'rxjs';
import { tap, retry, shareReplay, switchMap } from 'rxjs/operators';

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
    
    // State management
    private networkDataSubject = new BehaviorSubject<NetworkMapData[]>([]);
    public networkData$ = this.networkDataSubject.asObservable();
    
    private loadingSubject = new BehaviorSubject<boolean>(false);
    public isLoading$ = this.loadingSubject.asObservable();

    private pollingSub?: Subscription;

    constructor(private http: HttpClient) {
        // Start background pre-fetching automatically
        this.startPolling();
    }

    public startPolling(): void {
        if (this.pollingSub) return;

        // Poll every 60 seconds, start immediately
        this.pollingSub = timer(0, 60000).pipe(
            tap(() => this.loadingSubject.next(true)),
            switchMap(() => this.getNetworkMap('PROVINCIA').pipe(
                retry(2),
                tap({
                    next: (data) => {
                        this.networkDataSubject.next(data);
                        this.loadingSubject.next(false);
                    },
                    error: () => this.loadingSubject.next(false)
                })
            ))
        ).subscribe();
    }

    public refreshNow(): void {
        this.loadingSubject.next(true);
        this.getNetworkMap('PROVINCIA').subscribe({
            next: (data) => {
                this.networkDataSubject.next(data);
                this.loadingSubject.next(false);
            },
            error: () => this.loadingSubject.next(false)
        });
    }

    public getNetworkMap(zoneType: string = 'PROVINCIA'): Observable<NetworkMapData[]> {
        let params = new HttpParams().set('zoneType', zoneType);
        return this.http.get<NetworkMapData[]>(`${this.apiUrl}/map`, { params });
    }
}
