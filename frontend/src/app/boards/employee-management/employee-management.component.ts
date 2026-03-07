import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule, ReactiveFormsModule, FormBuilder, FormGroup, Validators } from '@angular/forms';
import { EmployeeService, EmpleadoActivarAccesoRequest, TipoDocumentoDTO } from '../../_services/employee.service';
import {
  EmpleadoDTO,
  EmpleadoCreateRequest,
  DocumentoEmpleadoDTO,
  EmpleadoAccessStatusDTO,
  AreaDTO,
  CargoDTO,
  TipoContratoDTO
} from '../../models/empleado.model';

@Component({
  selector: 'app-employee-management',
  standalone: true,
  imports: [CommonModule, FormsModule, ReactiveFormsModule],
  templateUrl: './employee-management.component.html',
  styleUrl: './employee-management.component.css'
})
export class EmployeeManagementComponent implements OnInit {

  // ── Estado general ─────────────────────────────────────────────────────────
  empleados: EmpleadoDTO[] = [];
  filteredEmpleados: EmpleadoDTO[] = [];
  searchTerm = '';
  isLoading = false;
  errorMsg = '';
  successMsg = '';

  // ── Vista seleccionada ─────────────────────────────────────────────────────
  view: 'list' | 'create' | 'detail' = 'list';
  selectedEmpleado: EmpleadoDTO | null = null;
  activeTab: 'datos' | 'documentos' | 'acceso' = 'datos';

  // ── Wizard de creación (3 pasos) ───────────────────────────────────────────
  currentStep = 1;
  personaExistente: EmpleadoDTO | null = null;
  cedulaBusqueda = '';
  buscandoPersona = false;
  personaEncontrada = false;

  personaForm!: FormGroup;
  laboralForm!: FormGroup;

  // ── Catálogos para dropdowns ───────────────────────────────────────────────
  areas: AreaDTO[] = [];
  cargos: CargoDTO[] = [];
  tiposContrato: TipoContratoDTO[] = [];

  // ── Panel de documentos ────────────────────────────────────────────────────
  documentos: DocumentoEmpleadoDTO[] = [];
  tiposDocumento: TipoDocumentoDTO[] = [];
  loadingDocs = false;
  uploadingDoc = false;
  showUploadForm = false;
  uploadFile: File | null = null;
  uploadIdTipo: number | undefined = undefined;
  uploadNumero = '';
  uploadDescripcion = '';

  // ── Panel de acceso ────────────────────────────────────────────────────────
  accessStatus: EmpleadoAccessStatusDTO | null = null;
  loadingAccess = false;
  showActivarForm = false;
  activarRol = '';
  activarEmpresa: number | null = null;
  activarAnio: number | null = null;
  activating = false;

  // Roles de empleado disponibles
  rolesEmpleado = ['TECNICO', 'ADMIN_TECNICOS', 'ADMIN_MASTER', 'ADMIN_VISUAL'];

  constructor(
    private fb: FormBuilder,
    private employeeService: EmployeeService
  ) {}

  ngOnInit(): void {
    this.buildForms();
    this.loadCatalogos();
    this.loadEmpleados();
  }

  // ── Inicialización ─────────────────────────────────────────────────────────

  private buildForms(): void {
    this.personaForm = this.fb.group({
      cedula:          ['', [Validators.required, Validators.minLength(10), Validators.maxLength(10)]],
      nombre:          ['', Validators.required],
      apellido:        ['', Validators.required],
      correo:          ['', Validators.email],
      celular:         [''],
      fechaNacimiento: ['']
    });

    this.laboralForm = this.fb.group({
      fechaIngreso:    ['', Validators.required],
      idArea:          [null, Validators.required],
      idCargo:         [null, Validators.required],
      idTipoContrato:  [null, Validators.required],
      idSucursal:      [null]
    });
  }

  private loadCatalogos(): void {
    this.employeeService.getAreas().subscribe(a => this.areas = a);
    this.employeeService.getCargos().subscribe(c => this.cargos = c);
    this.employeeService.getTiposContrato().subscribe(t => this.tiposContrato = t);
    this.employeeService.getTiposDocumento().subscribe(t => this.tiposDocumento = t);
  }

  loadEmpleados(): void {
    this.isLoading = true;
    this.employeeService.getAll().subscribe({
      next: list => {
        this.empleados = list;
        this.filteredEmpleados = list;
        this.isLoading = false;
      },
      error: err => {
        this.errorMsg = 'Error al cargar la lista de empleados.';
        this.isLoading = false;
      }
    });
  }

  // ── Búsqueda en tabla ──────────────────────────────────────────────────────

  onSearch(): void {
    const term = this.searchTerm.toLowerCase();
    this.filteredEmpleados = this.empleados.filter(e =>
      (e.nombre + ' ' + e.apellido + ' ' + e.cedula).toLowerCase().includes(term)
    );
  }

  // ── Navegación a detalle ───────────────────────────────────────────────────

  openDetail(emp: EmpleadoDTO): void {
    this.selectedEmpleado = emp;
    this.activeTab = 'datos';
    this.view = 'detail';
    this.resetPanels();
    this.loadDocumentos(emp.idEmpleado);
    this.loadAccessStatus(emp.cedula);
  }

  private resetPanels(): void {
    this.documentos = [];
    this.accessStatus = null;
    this.showUploadForm = false;
    this.showActivarForm = false;
    this.uploadFile = null;
    this.uploadIdTipo = undefined;
    this.uploadNumero = '';
    this.uploadDescripcion = '';
    this.errorMsg = '';
    this.successMsg = '';
  }

  goToList(): void {
    this.view = 'list';
    this.selectedEmpleado = null;
    this.loadEmpleados();
  }

  goToCreate(): void {
    this.view = 'create';
    this.currentStep = 1;
    this.personaExistente = null;
    this.personaEncontrada = false;
    this.personaForm.reset();
    this.laboralForm.reset();
    this.errorMsg = '';
    this.successMsg = '';
  }

  // ── Wizard de creación ─────────────────────────────────────────────────────

  buscarPersonaPorCedula(): void {
    const cedula = this.personaForm.get('cedula')?.value?.trim();
    if (!cedula || cedula.length < 10) return;

    this.buscandoPersona = true;
    this.personaEncontrada = false;
    this.personaExistente = null;

    this.employeeService.getByCedula(cedula).subscribe({
      next: emp => {
        // Ya es empleado — no debería llegarse aquí normalmente
        this.errorMsg = `La cédula ${cedula} ya pertenece al empleado "${emp.nombre} ${emp.apellido}".`;
        this.buscandoPersona = false;
      },
      error: () => {
        // 404 = no existe como empleado, podría existir como persona
        // En este caso habilitamos el formulario de persona
        this.personaEncontrada = false;
        this.buscandoPersona = false;
        this.errorMsg = '';
      }
    });
  }

  nextStep(): void {
    if (this.currentStep === 1 && this.personaForm.valid) {
      this.currentStep = 2;
    } else if (this.currentStep < 3) {
      this.personaForm.markAllAsTouched();
    }
  }

  prevStep(): void {
    if (this.currentStep > 1) this.currentStep--;
  }

  crearEmpleado(): void {
    if (this.personaForm.invalid || this.laboralForm.invalid) {
      this.personaForm.markAllAsTouched();
      this.laboralForm.markAllAsTouched();
      return;
    }

    const req: EmpleadoCreateRequest = {
      ...this.personaForm.value,
      ...this.laboralForm.value
    };

    this.isLoading = true;
    this.errorMsg = '';

    this.employeeService.create(req).subscribe({
      next: emp => {
        this.isLoading = false;
        this.currentStep = 3;
        this.selectedEmpleado = emp;
        this.successMsg = `Empleado "${emp.nombre} ${emp.apellido}" registrado correctamente.`;
      },
      error: err => {
        this.isLoading = false;
        this.errorMsg = err?.error?.message || 'Error al registrar el empleado.';
      }
    });
  }

  // ── Panel de documentos ────────────────────────────────────────────────────

  loadDocumentos(idEmpleado: number): void {
    this.loadingDocs = true;
    this.employeeService.getDocumentos(idEmpleado).subscribe({
      next: docs => {
        this.documentos = docs;
        this.loadingDocs = false;
      },
      error: () => { this.loadingDocs = false; }
    });
  }

  onFileSelected(event: Event): void {
    const input = event.target as HTMLInputElement;
    if (input.files?.length) this.uploadFile = input.files[0];
  }

  subirDocumento(): void {
    if (!this.uploadFile) {
      this.errorMsg = 'Debes seleccionar un archivo antes de subir.';
      return;
    }
    if (!this.selectedEmpleado) return;

    this.uploadingDoc = true;
    this.errorMsg = '';
    this.successMsg = '';

    this.employeeService.uploadDocumento(
      this.selectedEmpleado.idEmpleado,
      this.uploadFile,
      this.uploadIdTipo,
      this.uploadNumero || undefined,
      this.uploadDescripcion || undefined
    ).subscribe({
      next: doc => {
        this.documentos.unshift(doc);
        this.showUploadForm = false;
        this.uploadFile = null;
        this.uploadIdTipo = undefined;
        this.uploadNumero = '';
        this.uploadDescripcion = '';
        this.uploadingDoc = false;
        this.successMsg = 'Documento subido correctamente. Estado: PENDIENTE — un administrador deve validarlo.';
        this.loadAccessStatus(this.selectedEmpleado!.cedula);
      },
      error: err => {
        this.uploadingDoc = false;
        this.errorMsg = err?.error?.message || err?.message || 'Error al subir el documento. Verifica el archivo y vuelve a intentarlo.';
      }
    });
  }

  cambiarEstado(doc: DocumentoEmpleadoDTO, nuevoEstado: string): void {
    this.employeeService.cambiarEstadoDocumento(doc.idDocumento, nuevoEstado).subscribe({
      next: updated => {
        const idx = this.documentos.findIndex(d => d.idDocumento === doc.idDocumento);
        if (idx >= 0) this.documentos[idx] = updated;
        this.successMsg = `Documento actualizado a estado: ${nuevoEstado}`;
        if (this.selectedEmpleado) this.loadAccessStatus(this.selectedEmpleado.cedula);
      },
      error: err => { this.errorMsg = err?.error?.message || 'Error al cambiar el estado.'; }
    });
  }

  // ── Panel de acceso ────────────────────────────────────────────────────────

  loadAccessStatus(cedula: string): void {
    this.loadingAccess = true;
    this.employeeService.getAccessStatus(cedula).subscribe({
      next: status => {
        this.accessStatus = status;
        this.loadingAccess = false;
      },
      error: () => { this.loadingAccess = false; }
    });
  }

  activarAcceso(): void {
    if (!this.activarRol || !this.activarEmpresa || !this.activarAnio || !this.selectedEmpleado) return;
    this.activating = true;
    this.errorMsg = '';

    const req: EmpleadoActivarAccesoRequest = {
      rol: this.activarRol,
      idEmpresa: this.activarEmpresa,
      anioNacimiento: this.activarAnio
    };

    this.employeeService.activarAcceso(this.selectedEmpleado.cedula, req).subscribe({
      next: user => {
        this.activating = false;
        this.showActivarForm = false;
        this.successMsg = `Acceso habilitado. Username generado: ${user.username}`;
        this.loadAccessStatus(this.selectedEmpleado!.cedula);
        this.selectedEmpleado!.tieneUsuarioActivo = true;
        this.selectedEmpleado!.usernameSistema = user.username;
      },
      error: err => {
        this.activating = false;
        this.errorMsg = err?.error?.message || 'Error al habilitar el acceso.';
      }
    });
  }

  // ── Helpers de UI ──────────────────────────────────────────────────────────

  clearMessages(): void {
    this.errorMsg = '';
    this.successMsg = '';
  }

  getEstadoBadgeClass(codigo?: string): string {
    switch (codigo) {
      case 'ACTIVO':    return 'badge-activo';
      case 'PENDIENTE': return 'badge-pendiente';
      case 'RECHAZADO': return 'badge-rechazado';
      default:          return 'badge-default';
    }
  }
}
