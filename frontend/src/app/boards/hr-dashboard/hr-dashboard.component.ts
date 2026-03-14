import { Component, OnInit, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { EmployeeService } from '../../_services/employee.service';
import { CompanyService } from '../../_services/company.service';
import { EmpleadoDTO } from '../../models/empleado.model';
import { forkJoin, of } from 'rxjs';
import { catchError, delay } from 'rxjs/operators';

interface HRStat {
  label: string;
  value: string;
  icon: string;
  color: string;
  description: string;
}

@Component({
  selector: 'app-hr-dashboard',
  standalone: true,
  imports: [CommonModule, RouterModule],
  templateUrl: './hr-dashboard.component.html',
  styleUrls: ['./hr-dashboard.component.css']
})
export class HrDashboardComponent implements OnInit {
  stats: HRStat[] = [
    { label: 'Total Colaboradores', value: '...', icon: 'bi-people-fill', color: '#2563eb', description: 'Personal registrado en nómina' },
    { label: 'Accesos Activos', value: '...', icon: 'bi-shield-check', color: '#16a34a', description: 'Personal con credenciales de sistema' },
    { label: 'Pendientes Documentación', value: '...', icon: 'bi-file-earmark-exclamation', color: '#f59e0b', description: 'Expedientes por validar' },
    { label: 'Entidades / ISPs', value: '...', icon: 'bi-building', color: '#7c3aed', description: 'Empresas vinculadas al sistema' }
  ];
  isLoading = false;
  hasError = false;
  today = new Date();

  constructor(
    private employeeService: EmployeeService,
    private companyService: CompanyService,
    private cdr: ChangeDetectorRef
  ) {}

  ngOnInit(): void {
    this.loadHRData();
  }

  loadHRData(): void {
    this.isLoading = true;
    this.hasError = false;
    
    // Añadimos un pequeño retardo y reintento para evitar que el primer hit 
    // en un refresh (F5) devuelva listas vacías por falta de contexto de sesión
    forkJoin({
      empleados: this.employeeService.getAll().pipe(
        catchError(err => {
          console.error('Fallo en Dashboard (empleados):', err);
          this.hasError = true;
          return of(null);
        })
      ),
      empresas: this.companyService.getISPs().pipe(
        catchError(err => {
          console.error('Fallo en Dashboard (empresas):', err);
          this.hasError = true;
          return of(null);
        })
      )
    }).subscribe({
      next: (res) => {
        console.log('Dashboard Data Received:', {
          empleados: res.empleados?.length,
          empresas: res.empresas?.length
        });

        if (!res.empleados || !res.empresas) {
          console.warn('Respuesta incompleta, abortando actualización de stats');
          this.isLoading = false;
          return;
        }

        const totalEmp = res.empleados.length;
        const totalEmpresas = res.empresas.length;

        // Si recibimos 0 en todo pero no hubo error explícito, 
        // es una "falsa alarma" de la base de datos (contexto de sesión no listo)
        if (totalEmp === 0 && totalEmpresas === 0) {
          console.warn('Dashboard recibió ceros. Reintentando en 1.5s...');
          setTimeout(() => this.retryLoad(), 1500);
          return;
        }

        const activos = res.empleados.filter((e: EmpleadoDTO) => e.tieneUsuarioActivo).length;
        const pendientesDocs = res.empleados.filter((e: EmpleadoDTO) => !e.tieneDocumentoActivo).length;

        this.stats = [
          { label: 'Total Colaboradores', value: totalEmp.toString(), icon: 'bi-people-fill', color: '#2563eb', description: 'Personal registrado en nómina' },
          { label: 'Accesos Activos', value: activos.toString(), icon: 'bi-shield-check', color: '#16a34a', description: 'Personal con credenciales de sistema' },
          { label: 'Pendientes Documentación', value: pendientesDocs.toString(), icon: 'bi-file-earmark-exclamation', color: '#f59e0b', description: 'Expedientes por validar' },
          { label: 'Entidades / ISPs', value: totalEmpresas.toString(), icon: 'bi-building', color: '#7c3aed', description: 'Empresas vinculadas al sistema' }
        ];
        this.isLoading = false;
        this.hasError = false;
        
        // FORZAR ACTUALIZACIÓN DE UI
        this.cdr.detectChanges();
      },
      error: () => {
        this.hasError = true;
        this.isLoading = false;
        this.cdr.detectChanges();
      }
    });
  }

  private retryLoad(): void {
    // Solo reintentamos si seguimos en isLoading o si falló
    if (this.stats[0].value === '0') {
      this.loadHRData();
    }
  }
}
