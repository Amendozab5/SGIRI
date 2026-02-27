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
    filteredEmpresas: Empresa[] = []; // Added
    sucursales: Sucursal[] = [];
    selectedEmpresa: Empresa | null = null;
    loadingEmpresas = false;
    loadingSucursales = false;
    savingSucursal = false;
    savingEmpresa = false;
    showSucursalModal = false;
    showEmpresaModal = false;
    isEditingEmpresa = false;
    uploadingContract = false;
    error = '';
    activeFilter: string = 'TODOS'; // Added

    estadosGenerales: any[] = [];

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
        telefonoContacto: '',
        idEstado: null as number | null
    };

    constructor(
        private masterDataService: MasterDataService,
        private cdr: ChangeDetectorRef
    ) { }

    ngOnInit(): void {
        console.log('Initializing EntityManagementComponent...');
        this.loadEmpresas();
        this.loadPaises();
        this.loadEstados();
    }

    loadEstados(): void {
        this.masterDataService.getCatalogoItems('ESTADOS_GENERALES').subscribe({
            next: (data) => {
                console.log('Estados Generales loaded:', data);
                this.estadosGenerales = data;
                this.cdr.detectChanges();
            },
            error: (err) => console.error('Error loading estados:', err)
        });
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
            telefonoContacto: '',
            idEstado: this.estadosGenerales.find(e => e.codigo === 'ACTIVO' || e.codigo === 'ACTIVA')?.id || null
        };
        this.showEmpresaModal = true;
        this.isEditingEmpresa = false;
    }

    editEmpresa(empresa: Empresa): void {
        this.newEmpresa = {
            nombreComercial: empresa.nombreComercial,
            razonSocial: empresa.razonSocial,
            ruc: empresa.ruc,
            tipoEmpresa: empresa.tipoEmpresa || 'PRIVADA',
            correoContacto: empresa.correoContacto || '',
            telefonoContacto: empresa.telefonoContacto || '',
            idEstado: empresa.estado?.id || null
        };
        this.selectedEmpresa = empresa;
        this.isEditingEmpresa = true;
        this.showEmpresaModal = true;
    }

    saveEmpresa(): void {
        this.savingEmpresa = true;

        const action = this.isEditingEmpresa && this.selectedEmpresa
            ? this.masterDataService.updateEmpresa(this.selectedEmpresa.id, this.newEmpresa)
            : this.masterDataService.createEmpresa(this.newEmpresa);

        action.pipe(finalize(() => {
            this.savingEmpresa = false;
            this.cdr.detectChanges();
        }))
            .subscribe({
                next: (data) => {
                    if (this.isEditingEmpresa) {
                        const index = this.empresas.findIndex(e => e.id === data.id);
                        if (index !== -1) this.empresas[index] = data;
                        this.selectedEmpresa = data;
                    } else {
                        this.empresas.push(data);
                    }
                    this.applyFilter(); // Modified
                    this.showEmpresaModal = false;
                },
                error: (err) => {
                    console.error('Error saving empresa:', err);
                    alert('Error al guardar la empresa. Verifique los datos.');
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
                    this.applyFilter(); // Modified
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

    onFileSelected(event: any): void {
        const file: File = event.target.files[0];
        if (file) {
            this.uploadContract(file);
        }
    }

    uploadContract(file: File): void {
        this.uploadingContract = true;
        this.error = '';
        this.masterDataService.uploadContract(file)
            .pipe(finalize(() => {
                this.uploadingContract = false;
                this.cdr.detectChanges();
            }))
            .subscribe({
                next: (data) => {
                    this.empresas.push(data);
                    this.applyFilter(); // Modified
                    this.selectEmpresa(data);
                    alert('Empresa creada automáticamente desde el contrato: ' + data.nombreComercial);
                },
                error: (err) => {
                    console.error('Error uploading contract:', err);
                    const msg = err.error?.message || 'Error al procesar el contrato. Asegúrese de que el archivo sea válido.';
                    this.error = msg;
                    alert(msg);
                }
            });
    }

    // New methods added
    setFilter(status: string): void {
        this.activeFilter = status;
        this.applyFilter();
    }

    applyFilter(): void {
        if (this.activeFilter === 'TODOS') {
            this.filteredEmpresas = [...this.empresas];
        } else {
            this.filteredEmpresas = this.empresas.filter(emp => emp.estado?.codigo === this.activeFilter);
        }
        this.cdr.detectChanges();
    }
}
