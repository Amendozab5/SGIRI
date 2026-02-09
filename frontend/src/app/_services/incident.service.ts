import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { Incident } from '../models/incident';
import { IncidentRequest } from '../models/incident-request';
import { EIncidentStatus } from '../models/EIncidentStatus.enum';

const API_URL = 'http://localhost:8081/api/incidents';

@Injectable({
  providedIn: 'root'
})
export class IncidentService {

  constructor(private http: HttpClient) { }

  // For regular users to see their own incidents
  getMyIncidents(): Observable<Incident[]> {
    return this.http.get<Incident[]>(API_URL + '/my-incidents');
  }

  // For technicians/admins to see all incidents
  getAllIncidents(): Observable<Incident[]> {
    return this.http.get<Incident[]>(API_URL);
  }

  createIncident(incident: IncidentRequest): Observable<Incident> {
    return this.http.post<Incident>(API_URL, incident);
  }

  // For technicians/admins to update the status of an incident
  updateStatus(id: number, status: EIncidentStatus): Observable<Incident> {
    return this.http.put<Incident>(API_URL + `/${id}/status`, { status });
  }

  // For a technician to assign an incident to themselves
  assignToMe(id: number): Observable<Incident> {
    return this.http.put<Incident>(API_URL + `/${id}/assign`, {});
  }
}
