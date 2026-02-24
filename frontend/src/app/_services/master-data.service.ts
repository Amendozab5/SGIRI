import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { Catalogo, CatalogoItem } from '../models/catalogo';
import { Area, Cargo } from '../models/organization';
import { Empleado, Cliente } from '../models/personnel';
import { Empresa } from '../models/empresa';
import { Sucursal } from '../models/sucursal';
import { Servicio } from '../models/servicio';

const API_CATALOGOS = 'http://localhost:8081/api/catalogos';
const API_ORGANIZATION = 'http://localhost:8081/api/organization';
const API_PERSONNEL = 'http://localhost:8081/api/personnel';
const API_EMPRESAS = 'http://localhost:8081/api/empresas';
const API_SERVICIOS = 'http://localhost:8081/api/servicios';
const API_GEOGRAPHY = 'http://localhost:8081/api/geography';

@Injectable({
    providedIn: 'root'
})
export class MasterDataService {

    constructor(private http: HttpClient) { }

    // Catalogos
    getCatalogos(): Observable<Catalogo[]> {
        return this.http.get<Catalogo[]>(API_CATALOGOS);
    }

    getCatalogoItems(nombre: string): Observable<CatalogoItem[]> {
        return this.http.get<CatalogoItem[]>(`${API_CATALOGOS}/${nombre}/items`);
    }

    toggleItemStatus(itemId: number): Observable<any> {
        return this.http.put(`${API_CATALOGOS}/items/${itemId}/toggle-status`, {});
    }

    createCatalogoItem(catalogoId: number, item: any): Observable<CatalogoItem> {
        return this.http.post<CatalogoItem>(`${API_CATALOGOS}/${catalogoId}/items`, item);
    }

    // Organization
    getAreas(): Observable<Area[]> {
        return this.http.get<Area[]>(`${API_ORGANIZATION}/areas`);
    }

    getCargos(): Observable<Cargo[]> {
        return this.http.get<Cargo[]>(`${API_ORGANIZATION}/cargos`);
    }

    // Personnel
    getEmpleados(): Observable<Empleado[]> {
        return this.http.get<Empleado[]>(`${API_PERSONNEL}/empleados`);
    }

    getClientes(): Observable<Cliente[]> {
        return this.http.get<Cliente[]>(`${API_PERSONNEL}/clientes`);
    }

    // Empresas & Sucursales
    getEmpresas(): Observable<Empresa[]> {
        return this.http.get<Empresa[]>(API_EMPRESAS);
    }

    createEmpresa(empresa: any): Observable<Empresa> {
        return this.http.post<Empresa>(API_EMPRESAS, empresa);
    }

    getSucursales(empresaId: number): Observable<Sucursal[]> {
        return this.http.get<Sucursal[]>(`${API_EMPRESAS}/${empresaId}/sucursales`);
    }

    createSucursal(sucursal: any): Observable<Sucursal> {
        return this.http.post<Sucursal>(`${API_EMPRESAS}/sucursales`, sucursal);
    }

    getAllSucursales(): Observable<Sucursal[]> {
        return this.http.get<Sucursal[]>(`${API_EMPRESAS}/sucursales`);
    }

    getServicios(): Observable<Servicio[]> {
        return this.http.get<Servicio[]>(API_SERVICIOS);
    }

    getServiciosByEmpresa(empresaId: number): Observable<Servicio[]> {
        return this.http.get<Servicio[]>(`${API_SERVICIOS}/empresa/${empresaId}`);
    }

    // Geography
    getPaises(): Observable<any[]> {
        return this.http.get<any[]>(`${API_GEOGRAPHY}/paises`);
    }

    getCiudades(paisId: number): Observable<any[]> {
        return this.http.get<any[]>(`${API_GEOGRAPHY}/ciudades?paisId=${paisId}`);
    }

    getCantones(ciudadId: number): Observable<any[]> {
        return this.http.get<any[]>(`${API_GEOGRAPHY}/cantones?ciudadId=${ciudadId}`);
    }
}
