import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { Empresa } from '../models/empresa';

const COMPANY_API = 'http://localhost:8081/api/empresas/';

@Injectable({
    providedIn: 'root'
})
export class CompanyService {
    constructor(private http: HttpClient) { }

    getISPs(): Observable<Empresa[]> {
        return this.http.get<Empresa[]>(COMPANY_API + 'isps');
    }
}
