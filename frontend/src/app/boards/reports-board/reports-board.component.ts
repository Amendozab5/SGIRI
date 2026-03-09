import { Component, OnInit, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { ReporteService } from '../../_services/reporte.service';
import { ConfiguracionReporte, TicketResumenReporte, SlaTecnicoReporte, CsatAnalisisReporte, CsatDetalleReporte } from '../../models/reporte.model';
import { catchError, finalize, of } from 'rxjs';
import { ActivatedRoute } from '@angular/router';

@Component({
    selector: 'app-reports-board',
    templateUrl: './reports-board.component.html',
    styleUrls: ['./reports-board.component.css'],
    standalone: true,
    imports: [CommonModule, RouterModule]
})
export class ReportsBoardComponent implements OnInit {
    reportes: ConfiguracionReporte[] = [];
    ticketsData: TicketResumenReporte[] = [];
    slaData: SlaTecnicoReporte[] = [];
    csatData: CsatAnalisisReporte[] = [];
    csatDetalle: CsatDetalleReporte[] = [];
    statusFilter = 'TODOS';
    searchTerm = '';
    isLoading = true;
    selectedReport: string | null = null;

    constructor(
        private reporteService: ReporteService,
        private route: ActivatedRoute,
        private cdr: ChangeDetectorRef
    ) { }

    ngOnInit(): void {
        this.loadInitialData();
        // Escuchar parámetros de consulta para auto-seleccionar reporte
        this.route.queryParams.subscribe(params => {
            if (params['report']) {
                this.selectReport(params['report']);
            }
        });
    }

    loadInitialData(): void {
        this.isLoading = true;
        this.reporteService.getDisponibles().pipe(
            catchError(err => {
                console.error('Error al cargar configuraciones de reporte:', err);
                return of([]);
            }),
            finalize(() => {
                this.isLoading = false;
                this.cdr.detectChanges();
            })
        ).subscribe(data => {
            this.reportes = data;
            // Solo auto-seleccionar si no hay uno seleccionado por parámetro
            if (this.reportes.length > 0 && !this.selectedReport) {
                this.selectReport(this.reportes[0].codigoUnico);
            }
        });
    }

    selectReport(codigo: string): void {
        this.selectedReport = codigo;
        if (codigo === 'TICKETS_RESUMEN' || codigo === 'TICKET_GESTION') {
            this.loadTicketsData();
        } else if (codigo === 'SLA_TECNICO') {
            this.loadSlaData();
        } else if (codigo === 'CSAT_ANALISIS') {
            this.loadCsatData();
            this.loadCsatDetalle();
        }
        this.cdr.detectChanges();
    }

    onStatusChange(status: string): void {
        this.statusFilter = status;
        if (this.selectedReport === 'TICKETS_RESUMEN' || this.selectedReport === 'TICKET_GESTION') {
            this.loadTicketsData();
        }
    }

    onSearch(event: any): void {
        this.searchTerm = event.target.value;
        if (this.selectedReport === 'TICKETS_RESUMEN' || this.selectedReport === 'TICKET_GESTION') {
            this.loadTicketsData();
        }
    }

    downloadPdf(): void {
        let obs$;
        if (this.selectedReport === 'SLA_TECNICO') {
            obs$ = this.reporteService.exportSlaPdf();
        } else if (this.selectedReport === 'CSAT_ANALISIS') {
            obs$ = this.reporteService.exportCsatPdf();
        } else if (this.selectedReport === 'TICKET_GESTION' || this.selectedReport === 'TICKETS_RESUMEN') {
            obs$ = this.reporteService.exportTicketsPdf(this.statusFilter, this.searchTerm);
        }

        if (obs$) {
            obs$.subscribe(blob => {
                const url = window.URL.createObjectURL(blob);
                const a = document.createElement('a');
                a.href = url;
                a.download = `${this.selectedReport?.toLowerCase()}_report.pdf`;
                a.click();
                window.URL.revokeObjectURL(url);
            });
        }
    }

    exportToExcel(): void {
        let dataToExport: any[] = [];
        let fileName = 'reporte';

        if (this.selectedReport === 'TICKET_GESTION' || this.selectedReport === 'TICKETS_RESUMEN') {
            dataToExport = this.ticketsData;
            fileName = 'gestion_tickets';
        } else if (this.selectedReport === 'SLA_TECNICO') {
            dataToExport = this.slaData;
            fileName = 'sla_tecnico';
        } else if (this.selectedReport === 'CSAT_ANALISIS') {
            dataToExport = this.csatDetalle;
            fileName = 'satisfaccion_cliente';
        }

        if (dataToExport.length > 0) {
            const replacer = (key: any, value: any) => value === null ? '' : value;
            const header = Object.keys(dataToExport[0]);
            let csv = dataToExport.map(row => header.map(fieldName => JSON.stringify(row[fieldName as keyof any], replacer)).join(','));
            csv.unshift(header.join(','));
            let csvArray = csv.join('\r\n');

            var blob = new Blob([csvArray], { type: 'text/csv' });
            var url = window.URL.createObjectURL(blob);
            var a = document.createElement("a");
            a.href = url;
            a.download = fileName + ".csv";
            a.click();
            window.URL.revokeObjectURL(url);
        }
    }

    loadTicketsData(): void {
        this.reporteService.getTicketsResumen(this.statusFilter, this.searchTerm).subscribe(data => {
            this.ticketsData = data;
            this.cdr.detectChanges();
        });
    }

    loadSlaData(): void {
        this.reporteService.getSlaTecnico().subscribe(data => {
            this.slaData = data;
            this.cdr.detectChanges();
        });
    }

    loadCsatData(): void {
        this.reporteService.getCsatAnalisis().subscribe(data => {
            this.csatData = data;
            this.cdr.detectChanges();
        });
    }

    loadCsatDetalle(): void {
        this.reporteService.getCsatDetalle().subscribe(data => {
            this.csatDetalle = data;
            this.cdr.detectChanges();
        });
    }
}
