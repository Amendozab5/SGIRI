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
    // Component for managing entities (ISPs, public entities) and their branches/clients
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
    activeFilter: string = 'TODOS';
    isEditingSucursal = false;
    selectedSucursal: Sucursal | null = null;
    totalActivas = 0;
    totalInactivas = 0;

    // Client Management State
    viewMode: 'SUCURSALES' | 'CLIENTES' = 'SUCURSALES';
    clientes: any[] = [];
    loadingClientes = false;
    showClienteModal = false;
    savingCliente = false;
    importingClientes = false; // Added
    importMessage: string | null = null; // Added
    importError = false; // Added
    newCliente = {
        cedula: '',
        nombre: '',
        apellido: '',
        correo: '',
        celular: '',
        fechaNacimiento: null as string | null,
        idSucursal: null as number | null,
        fechaInicioContrato: null as string | null,
        fechaFinContrato: null as string | null
    };

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

    openEmpresaModal(empresa?: Empresa): void {
        if (empresa) {
            this.editEmpresa(empresa);
            return;
        }
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

    autoCargarEmpresa(): void {
        console.log('Auto-cargar empresa (IA) invocado.');
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

    openSucursalModal(sucursal?: Sucursal): void {
        if (sucursal) {
            this.editSucursal(sucursal);
            return;
        }
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
        this.isEditingSucursal = false;
    }

    editSucursal(sucursal: Sucursal): void {
        this.newSucursal = {
            nombre: sucursal.nombre,
            direccion: sucursal.direccion,
            telefono: sucursal.telefono,
            idPais: null,
            idCiudad: sucursal.idCiudad,
            idCanton: sucursal.idCanton
        };
        this.selectedSucursal = sucursal;
        this.isEditingSucursal = true;
        this.showSucursalModal = true;
    }

    saveSucursal(): void {
        if (!this.selectedEmpresa) return;

        this.savingSucursal = true;
        const request = {
            ...this.newSucursal,
            idEmpresa: this.selectedEmpresa.id
        };

        const action = this.isEditingSucursal && this.selectedSucursal
            ? this.masterDataService.updateSucursal(this.selectedSucursal.id, request)
            : this.masterDataService.createSucursal(request);

        action.pipe(finalize(() => {
                this.savingSucursal = false;
                this.cdr.detectChanges();
            }))
            .subscribe({
                next: (data) => {
                    if (this.isEditingSucursal) {
                        const index = this.sucursales.findIndex(s => s.id === data.id);
                        if (index !== -1) this.sucursales[index] = data;
                    } else {
                        this.sucursales.push(data);
                    }
                    this.showSucursalModal = false;
                },
                error: (err) => {
                    console.error('Error saving sucursal:', err);
                    alert('Error al guardar la sucursal');
                }
            });
    }

    // Client Management Methods
    setViewMode(mode: 'SUCURSALES' | 'CLIENTES'): void {
        this.viewMode = mode;
        if (mode === 'CLIENTES' && this.selectedEmpresa) {
            this.loadClientes();
        }
    }

    loadClientes(): void {
        if (!this.selectedEmpresa) return;
        this.loadingClientes = true;
        this.masterDataService.getClientesByEmpresa(this.selectedEmpresa.id)
            .pipe(finalize(() => {
                this.loadingClientes = false;
                this.cdr.detectChanges();
            }))
            .subscribe({
                next: (data) => this.clientes = data,
                error: (err) => console.error('Error loading clientes:', err)
            });
    }

    openClienteModal(): void {
        this.newCliente = {
            cedula: '',
            nombre: '',
            apellido: '',
            correo: '',
            celular: '',
            fechaNacimiento: null,
            idSucursal: this.sucursales.length > 0 ? this.sucursales[0].id : null,
            fechaInicioContrato: new Date().toISOString().split('T')[0],
            fechaFinContrato: null
        };
        this.showClienteModal = true;
    }

    saveCliente(): void {
        if (!this.newCliente.idSucursal) {
            alert('Debe seleccionar una sucursal para el cliente.');
            return;
        }

        this.savingCliente = true;
        this.masterDataService.crearCliente(this.newCliente)
            .pipe(finalize(() => {
                this.savingCliente = false;
                this.cdr.detectChanges();
            }))
            .subscribe({
                next: (data) => {
                    this.loadClientes();
                    this.showClienteModal = false;
                    alert('Cliente pre-registrado exitosamente.');
                },
                error: (err) => {
                    console.error('Error saving cliente:', err);
                    alert(err.error?.message || 'Error al guardar el cliente.');
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
        
        // Update counts for the stats strip
        this.totalActivas = this.empresas.filter(e => e.estado?.codigo === 'ACTIVO').length;
        this.totalInactivas = this.empresas.filter(e => e.estado?.codigo === 'INACTIVO').length;
        
        this.cdr.detectChanges();
    }

    onClientImportSelected(event: any): void {
        const file: File = event.target.files[0];
        if (!file) return;

        // Validamos que haya una sucursal seleccionada (tomamos la primera si no hay una modal abierta)
        const idSucursal = this.sucursales.length > 0 ? this.sucursales[0].id : null;
        
        if (!idSucursal) {
            this.importMessage = 'Primero debe crear al menos una sucursal.';
            this.importError = true;
            return;
        }

        this.importingClientes = true;
        this.importMessage = 'Procesando archivo excel...';
        this.importError = false;

        this.masterDataService.importClientes(file, idSucursal).subscribe({
            next: (result) => {
                this.importingClientes = false;
                this.importMessage = `¡Éxito! Se importaron ${result.length} clientes.`;
                this.importError = false;
                this.loadClientes(); // Corrected call (no arguments)
                
                // Limpiar mensaje después de 5 segundos
                setTimeout(() => this.importMessage = null, 5000);
            },
            error: (err) => {
                this.importingClientes = false;
                this.importMessage = 'Error al importar archivo. Verifique el formato.';
                this.importError = true;
                console.error('Import error:', err);
                setTimeout(() => this.importMessage = null, 8000);
            }
        });

        // Reset input
        event.target.value = '';
    }
}
