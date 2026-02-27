import { Component, OnInit, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { MasterDataService } from '../../_services/master-data.service';
import { Empresa } from '../../models/empresa';
import { Sucursal } from '../../models/sucursal';
import { finalize } from 'rxjs/operators';

@Component({
    selector: 'app-entity-management',
    standalone: true,
    imports: [CommonModule, FormsModule],
    templateUrl: './entity-management.component.html',
    styleUrls: ['./entity-management.component.css']
})
export class EntityManagementComponent implements OnInit {
    empresas: Empresa[] = [];
    sucursales: Sucursal[] = [];
    selectedEmpresa: Empresa | null = null;
    loadingEmpresas = false;
    loadingSucursales = false;
    savingSucursal = false;
    savingEmpresa = false;
    showSucursalModal = false;
    showEmpresaModal = false;
    error = '';

    // Geography lists
    paises: any[] = [];
    ciudades: any[] = [];
    cantones: any[] = [];

    newSucursal = {
        nombre: '',
        direccion: '',
        telefono: '',
        idPais: null as number | null,
        idCiudad: null as number | null,
        idCanton: null as number | null
    };

    newEmpresa = {
        nombreComercial: '',
        razonSocial: '',
        ruc: '',
        tipoEmpresa: 'PRIVADA',
        correoContacto: '',
        telefonoContacto: ''
    };

    constructor(
        private masterDataService: MasterDataService,
        private cdr: ChangeDetectorRef
    ) { }

    ngOnInit(): void {
        console.log('Initializing EntityManagementComponent...');
        this.loadEmpresas();
        this.loadPaises();
    }

    loadPaises(): void {
        this.masterDataService.getPaises().subscribe({
            next: (data) => this.paises = data,
            error: (err) => console.error('Error loading paises:', err)
        });
    }

    onPaisChange(paisId: number): void {
        this.newSucursal.idCiudad = null;
        this.newSucursal.idCanton = null;
        this.ciudades = [];
        this.cantones = [];
        if (paisId) {
            this.masterDataService.getCiudades(paisId).subscribe({
                next: (data) => {
                    this.ciudades = data;
                    this.cdr.detectChanges();
                }
            });
        }
    }

    onCiudadChange(ciudadId: number): void {
        this.newSucursal.idCanton = null;
        this.cantones = [];
        if (ciudadId) {
            this.masterDataService.getCantones(ciudadId).subscribe({
                next: (data) => {
                    this.cantones = data;
                    this.cdr.detectChanges();
                }
            });
        }
    }

    openEmpresaModal(): void {
        this.newEmpresa = {
            nombreComercial: '',
            razonSocial: '',
            ruc: '',
            tipoEmpresa: 'PRIVADA',
            correoContacto: '',
            telefonoContacto: ''
        };
        this.showEmpresaModal = true;
    }

    saveEmpresa(): void {
        this.savingEmpresa = true;
        this.masterDataService.createEmpresa(this.newEmpresa)
            .pipe(finalize(() => {
                this.savingEmpresa = false;
                this.cdr.detectChanges();
            }))
            .subscribe({
                next: (data) => {
                    this.empresas.push(data);
                    this.showEmpresaModal = false;
                },
                error: (err) => {
                    console.error('Error saving empresa:', err);
                    alert('Error al guardar la empresa. Verifique que el RUC no esté duplicado.');
                }
            });
    }

    openSucursalModal(): void {
        this.newSucursal = {
            nombre: '',
            direccion: '',
            telefono: '',
            idPais: null,
            idCiudad: null,
            idCanton: null
        };
        this.ciudades = [];
        this.cantones = [];
        this.showSucursalModal = true;
    }

    saveSucursal(): void {
        if (!this.selectedEmpresa) return;

        this.savingSucursal = true;
        const request = {
            ...this.newSucursal,
            idEmpresa: this.selectedEmpresa.id
        };

        this.masterDataService.createSucursal(request)
            .pipe(finalize(() => {
                this.savingSucursal = false;
                this.cdr.detectChanges();
            }))
            .subscribe({
                next: (data) => {
                    this.sucursales.push(data);
                    this.showSucursalModal = false;
                },
                error: (err) => {
                    console.error('Error saving sucursal:', err);
                    alert('Error al guardar la sucursal');
                }
            });
    }

    loadEmpresas(): void {
        this.loadingEmpresas = true;
        this.error = '';
        this.masterDataService.getEmpresas()
            .pipe(finalize(() => {
                this.loadingEmpresas = false;
                this.cdr.detectChanges();
            }))
            .subscribe({
                next: (data) => {
                    console.log('Empresas loaded result:', data);
                    this.empresas = data;
                },
                error: (err) => {
                    console.error('Error loading empresas:', err);
                    this.error = 'Error al cargar las empresas. Por favor verifique la conexión con el servidor.';
                }
            });
    }

    selectEmpresa(empresa: Empresa): void {
        console.log('Selected empresa:', empresa);
        this.selectedEmpresa = empresa;
        this.loadingSucursales = true;
        this.sucursales = [];
        this.masterDataService.getSucursales(empresa.id)
            .pipe(finalize(() => {
                this.loadingSucursales = false;
                this.cdr.detectChanges();
            }))
            .subscribe({
                next: (data) => {
                    console.log('Sucursales loaded result:', data);
                    this.sucursales = data;
                },
                error: (err) => {
                    console.error('Error loading sucursales:', err);
                    this.error = 'Error al cargar las sucursales';
                }
            });
    }
}
