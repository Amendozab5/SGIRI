import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { Pais } from '../models/pais';
import { Ciudad } from '../models/ciudad';
import { Canton } from '../models/canton';

const API_URL = 'http://localhost:8081/api/geography';

@Injectable({
  providedIn: 'root'
})
export class GeographyService {

  constructor(private http: HttpClient) { }

  getPaises(): Observable<Pais[]> {
    return this.http.get<Pais[]>(API_URL + '/paises');
  }

  getCiudades(paisId: number): Observable<Ciudad[]> {
    return this.http.get<Ciudad[]>(API_URL + '/ciudades', { params: { paisId: paisId.toString() } });
  }

  getCantones(ciudadId: number): Observable<Canton[]> {
    return this.http.get<Canton[]>(API_URL + '/cantones', { params: { ciudadId: ciudadId.toString() } });
  }
}
