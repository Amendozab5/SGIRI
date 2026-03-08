import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { NotificacionWeb } from '../models/notification';

const API_URL = 'http://localhost:8081/api/notificaciones/';

@Injectable({
    providedIn: 'root'
})
export class NotificationService {

    constructor(private http: HttpClient) { }

    getMisNotificaciones(): Observable<NotificacionWeb[]> {
        return this.http.get<NotificacionWeb[]>(API_URL + 'mis-notificaciones');
    }

    getUnreadCount(): Observable<{ unreadCount: number }> {
        return this.http.get<{ unreadCount: number }>(API_URL + 'unread-count');
    }

    marcarComoLeida(id: number): Observable<any> {
        return this.http.patch(API_URL + id + '/leer', {});
    }

    marcarTodasComoLeidas(): Observable<any> {
        return this.http.patch(API_URL + 'leer-todas', {});
    }
}
