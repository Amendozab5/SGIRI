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
    { label: 'Total Colaboradores', value: '...', icon: 'bi-people-fill', color: '#4f46e5', description: 'Personal registrado en nómina' },
    { label: 'Accesos Activos', value: '...', icon: 'bi-shield-check', color: '#10b981', description: 'Personal con credenciales de sistema' },
    { label: 'Pendientes Documentación', value: '...', icon: 'bi-exclamation-octagon', color: '#f59e0b', description: 'Expedientes por validar' },
    { label: 'Entidades / ISPs', value: '...', icon: 'bi-building', color: '#7c3aed', description: 'Empresas vinculadas al sistema' }
  ];
  totalEmpleados: number = 0;
  totalContratos: number = 0;
  empresas_isps: any[] = [];
  recentEmployees: EmpleadoDTO[] = [];
  areaDistribution: { name: string, count: number, percentage: number }[] = [];
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
        if (!res.empleados || !res.empresas) {
          this.isLoading = false;
          return;
        }

        const totalEmp = res.empleados.length;
        const totalEmpresas = res.empresas.length;

        if (totalEmp === 0 && totalEmpresas === 0) {
          setTimeout(() => this.retryLoad(), 1500);
          return;
        }

        const activos = res.empleados.filter((e: EmpleadoDTO) => e.tieneUsuarioActivo).length;
        const pendientesDocs = res.empleados.filter((e: EmpleadoDTO) => !e.tieneDocumentoActivo).length;

        this.totalEmpleados = totalEmp;
        this.totalContratos = totalEmpresas;
        this.empresas_isps = res.empresas;

        // Recent Employees (last 5)
        this.recentEmployees = [...res.empleados]
          .sort((a, b) => new Date(b.fechaIngreso).getTime() - new Date(a.fechaIngreso).getTime())
          .slice(0, 5);

        // Area Distribution
        const counts: { [key: string]: number } = {};
        res.empleados.forEach((e: EmpleadoDTO) => {
          const area = e.nombreArea || 'Sin Área';
          counts[area] = (counts[area] || 0) + 1;
        });

        this.areaDistribution = Object.keys(counts).map(name => ({
          name,
          count: counts[name],
          percentage: (counts[name] / totalEmp) * 100
        })).sort((a, b) => b.count - a.count);

        this.stats = [
          { label: 'Total Colaboradores', value: totalEmp.toString(), icon: 'bi-people-fill', color: '#2563eb', description: 'Personal registrado en nómina' },
          { label: 'Accesos Activos', value: activos.toString(), icon: 'bi-shield-check', color: '#16a34a', description: 'Personal con credenciales de sistema' },
          { label: 'Pendientes Documentación', value: pendientesDocs.toString(), icon: 'bi-exclamation-octagon', color: '#f59e0b', description: 'Expedientes por validar' },
          { label: 'Entidades / ISPs', value: totalEmpresas.toString(), icon: 'bi-building', color: '#7c3aed', description: 'Empresas vinculadas al sistema' }
        ];
        
        this.isLoading = false;
        this.hasError = false;
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
