import { Component, OnInit, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { TicketService } from '../_services/ticket.service';
import { MasterDataService } from '../_services/master-data.service';
import { TokenStorageService } from '../_services/token-storage.service';
import { CatalogoItem } from '../models/catalogo';
import { Servicio } from '../models/servicio';
import { Sucursal } from '../models/sucursal';

@Component({
  selector: 'app-report-incident',
  templateUrl: './report-incident.component.html',
  styleUrls: ['./report-incident.component.css'],
  standalone: true,
  imports: [CommonModule, FormsModule]
})
export class ReportIncidentComponent implements OnInit {

  form: any = {
    asunto: '',
    descripcion: '',
    idCategoriaItem: null,
    idServicio: null,
    idSucursal: null
  };

  categorias: CatalogoItem[] = [];
  servicios: Servicio[] = [];
  sucursales: Sucursal[] = [];

  isSuccessful = false;
  isReportFailed = false;
  errorMessage = '';
  currentUser: any;
  isCliente = false;
  showSucursal = true;

  constructor(
    private ticketService: TicketService,
    private masterDataService: MasterDataService,
    private tokenStorageService: TokenStorageService,
    private router: Router,
    private cdr: ChangeDetectorRef
  ) { }

  ngOnInit(): void {
    this.currentUser = this.tokenStorageService.getUser();
    this.isCliente = this.currentUser && this.currentUser.roles && this.currentUser.roles.includes('ROLE_CLIENTE');
    // Hide sucursal if user is a client, as requested
    this.showSucursal = !this.isCliente;
    this.loadMasterData();
  }

  loadMasterData(): void {
    this.masterDataService.getCatalogoItems('CATEGORIA_TICKET').subscribe({
      next: (data) => {
        this.categorias = data;
        this.cdr.detectChanges();
      },
      error: (err) => console.error('Error loading categories', err)
    });

    if (this.currentUser && this.currentUser.idEmpresa) {
      const empresaId = this.currentUser.idEmpresa;

      this.masterDataService.getSucursales(empresaId).subscribe({
        next: (data) => {
          this.sucursales = data;
          this.cdr.detectChanges();
        },
        error: (err) => console.error('Error loading sucursales', err)
      });

      this.masterDataService.getServiciosByEmpresa(empresaId).subscribe({
        next: (data) => {
          this.servicios = data;
          this.cdr.detectChanges();
        },
        error: (err) => console.error('Error loading services', err)
      });
    } else {
      // Fallback or Admin view
      this.masterDataService.getAllSucursales().subscribe({
        next: (data) => {
          this.sucursales = data;
          this.cdr.detectChanges();
        },
        error: (err) => console.error('Error loading all sucursales', err)
      });

      this.masterDataService.getServicios().subscribe({
        next: (data) => {
          this.servicios = data;
          this.cdr.detectChanges();
        },
        error: (err) => console.error('Error loading all services', err)
      });
    }
  }

  onSubmit(): void {
    this.ticketService.createTicket(this.form).subscribe({
      next: (data: any) => {
        this.isSuccessful = true;
        this.isReportFailed = false;
        // Redirect after 3 seconds
        setTimeout(() => {
          this.router.navigate(['/home/user']);
        }, 3000);
      },
      error: (err: any) => {
        this.errorMessage = err.error.message || err.statusText;
        this.isReportFailed = true;
      }
    });
  }
}