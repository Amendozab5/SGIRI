package com.apweb.backend.controller;

import com.apweb.backend.model.ConfiguracionReporte;
import com.apweb.backend.model.VwResumenTickets;
import com.apweb.backend.model.VwSlaTecnico;
import com.apweb.backend.model.VwCsatAnalisis;
import com.apweb.backend.model.VwCsatDetalle;
import com.apweb.backend.service.ReporteService;
import com.apweb.backend.service.PdfReporteService;
import com.apweb.backend.service.ExcelReporteService;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.core.io.InputStreamResource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;

import java.time.LocalDateTime;
import java.util.List;
import java.io.ByteArrayInputStream;

@RestController
@RequestMapping("/api/reportes")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class ReporteController {

    private final ReporteService reporteService;
    private final PdfReporteService pdfReporteService;
    private final ExcelReporteService excelReporteService;

    /**
     * Lista todos los reportes configurados disponibles para administradores.
     */
    @GetMapping("/disponibles")
    @PreAuthorize("hasRole('ROLE_ADMIN_MASTER') or hasRole('ROLE_ADMIN_CONTRATOS') or hasRole('ROLE_ADMIN_TECNICOS')")
    public ResponseEntity<List<ConfiguracionReporte>> getDisponibles() {
        return ResponseEntity.ok(reporteService.getReportesDisponibles());
    }

    /**
     * Obtiene los datos de la vista de resumen de tickets para administración.
     */
    @GetMapping("/data/tickets-resumen")
    @PreAuthorize("hasRole('ROLE_ADMIN_MASTER') or hasRole('ROLE_ADMIN_CONTRATOS') or hasRole('ROLE_ADMIN_TECNICOS')")
    public ResponseEntity<List<VwResumenTickets>> getTicketsResumen(
            @RequestParam(name = "status", required = false) String status,
            @RequestParam(name = "search", required = false) String search,
            @RequestParam(name = "desde", required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime desde,
            @RequestParam(name = "hasta", required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime hasta) {

        return ResponseEntity.ok(reporteService.getTicketsData(null, status, search, desde, hasta));
    }

    @GetMapping("/export/tickets/pdf")
    @PreAuthorize("hasRole('ROLE_ADMIN_MASTER') or hasRole('ROLE_ADMIN_CONTRATOS') or hasRole('ROLE_ADMIN_TECNICOS')")
    public ResponseEntity<InputStreamResource> exportTicketsPdf(
            @RequestParam(name = "status", required = false) String status,
            @RequestParam(name = "search", required = false) String search,
            @RequestParam(name = "desde", required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime desde,
            @RequestParam(name = "hasta", required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime hasta) {

        long start = System.currentTimeMillis();
        java.util.Map<String, Object> params = new java.util.HashMap<>();
        params.put("status", status);
        params.put("search", search);
        params.put("desde", desde);
        params.put("hasta", hasta);

        try {
            List<VwResumenTickets> data = reporteService.getTicketsData(null, status, search, desde, hasta);
            ByteArrayInputStream bis = pdfReporteService.generateTicketsReport(data);

            reporteService.registrarGeneracion("TICKETS_RESUMEN", "PDF", true, null, System.currentTimeMillis() - start,
                    params);

            HttpHeaders headers = new HttpHeaders();
            headers.add("Content-Disposition", "attachment; filename=tickets_report.pdf");

            return ResponseEntity
                    .ok()
                    .headers(headers)
                    .contentType(MediaType.APPLICATION_PDF)
                    .body(new InputStreamResource(bis));
        } catch (Exception e) {
            reporteService.registrarGeneracion("TICKETS_RESUMEN", "PDF", false, e.getMessage(),
                    System.currentTimeMillis() - start, params);
            throw e;
        }
    }

    @GetMapping("/export/sla/pdf")
    @PreAuthorize("hasRole('ROLE_ADMIN_MASTER') or hasRole('ROLE_ADMIN_CONTRATOS') or hasRole('ROLE_ADMIN_TECNICOS')")
    public ResponseEntity<InputStreamResource> exportSlaPdf() {
        long start = System.currentTimeMillis();
        try {
            List<VwSlaTecnico> data = reporteService.getSlaTecnicoData();
            ByteArrayInputStream bis = pdfReporteService.generateSlaReport(data);

            reporteService.registrarGeneracion("SLA_TECNICO", "PDF", true, null, System.currentTimeMillis() - start,
                    null);

            HttpHeaders headers = new HttpHeaders();
            headers.add("Content-Disposition", "attachment; filename=sla_report.pdf");

            return ResponseEntity
                    .ok()
                    .headers(headers)
                    .contentType(MediaType.APPLICATION_PDF)
                    .body(new InputStreamResource(bis));
        } catch (Exception e) {
            reporteService.registrarGeneracion("SLA_TECNICO", "PDF", false, e.getMessage(),
                    System.currentTimeMillis() - start, null);
            throw e;
        }
    }

    @GetMapping("/export/csat/pdf")
    @PreAuthorize("hasRole('ROLE_ADMIN_MASTER') or hasRole('ROLE_ADMIN_CONTRATOS') or hasRole('ROLE_ADMIN_TECNICOS')")
    public ResponseEntity<InputStreamResource> exportCsatPdf() {
        long start = System.currentTimeMillis();
        try {
            List<VwCsatDetalle> data = reporteService.getCsatDetalleData();
            ByteArrayInputStream bis = pdfReporteService.generateCsatDetalleReport(data);

            reporteService.registrarGeneracion("CSAT_ANALISIS", "PDF", true, null, System.currentTimeMillis() - start,
                    null);

            HttpHeaders headers = new HttpHeaders();
            headers.add("Content-Disposition", "attachment; filename=csat_detailed_report.pdf");

            return ResponseEntity
                    .ok()
                    .headers(headers)
                    .contentType(MediaType.APPLICATION_PDF)
                    .body(new InputStreamResource(bis));
        } catch (Exception e) {
            reporteService.registrarGeneracion("CSAT_FEEDBACK", "PDF", false, e.getMessage(),
                    System.currentTimeMillis() - start, null);
            throw e;
        }
    }

    @GetMapping("/export/tickets/excel")
    @PreAuthorize("hasRole('ROLE_ADMIN_MASTER') or hasRole('ROLE_ADMIN_CONTRATOS') or hasRole('ROLE_ADMIN_TECNICOS')")
    public ResponseEntity<InputStreamResource> exportTicketsExcel(
            @RequestParam(name = "status", required = false) String status,
            @RequestParam(name = "search", required = false) String search,
            @RequestParam(name = "desde", required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime desde,
            @RequestParam(name = "hasta", required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime hasta)
            throws Exception {

        long start = System.currentTimeMillis();
        java.util.Map<String, Object> params = new java.util.HashMap<>();
        params.put("status", status);
        params.put("search", search);
        params.put("desde", desde);
        params.put("hasta", hasta);

        try {
            List<VwResumenTickets> data = reporteService.getTicketsData(null, status, search, desde, hasta);
            ByteArrayInputStream bis = excelReporteService.generateTicketsExcel(data);

            reporteService.registrarGeneracion("TICKETS_RESUMEN", "EXCEL", true, null,
                    System.currentTimeMillis() - start, params);

            HttpHeaders headers = new HttpHeaders();
            headers.add("Content-Disposition", "attachment; filename=tickets_report.xlsx");

            return ResponseEntity
                    .ok()
                    .headers(headers)
                    .contentType(MediaType
                            .parseMediaType("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"))
                    .body(new InputStreamResource(bis));
        } catch (Exception e) {
            reporteService.registrarGeneracion("TICKETS_RESUMEN", "EXCEL", false, e.getMessage(),
                    System.currentTimeMillis() - start, params);
            throw e;
        }
    }

    @GetMapping("/export/sla/excel")
    @PreAuthorize("hasRole('ROLE_ADMIN_MASTER') or hasRole('ROLE_ADMIN_CONTRATOS') or hasRole('ROLE_ADMIN_TECNICOS')")
    public ResponseEntity<InputStreamResource> exportSlaExcel() throws Exception {
        long start = System.currentTimeMillis();
        try {
            List<VwSlaTecnico> data = reporteService.getSlaTecnicoData();
            ByteArrayInputStream bis = excelReporteService.generateSlaExcel(data);

            reporteService.registrarGeneracion("SLA_TECNICO", "EXCEL", true, null, System.currentTimeMillis() - start,
                    null);

            HttpHeaders headers = new HttpHeaders();
            headers.add("Content-Disposition", "attachment; filename=sla_report.xlsx");

            return ResponseEntity
                    .ok()
                    .headers(headers)
                    .contentType(MediaType
                            .parseMediaType("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"))
                    .body(new InputStreamResource(bis));
        } catch (Exception e) {
            reporteService.registrarGeneracion("SLA_TECNICO", "EXCEL", false, e.getMessage(),
                    System.currentTimeMillis() - start, null);
            throw e;
        }
    }

    @GetMapping("/export/csat/excel")
    @PreAuthorize("hasRole('ROLE_ADMIN_MASTER') or hasRole('ROLE_ADMIN_CONTRATOS') or hasRole('ROLE_ADMIN_TECNICOS')")
    public ResponseEntity<InputStreamResource> exportCsatExcel() throws Exception {
        long start = System.currentTimeMillis();
        try {
            List<VwCsatDetalle> data = reporteService.getCsatDetalleData();
            ByteArrayInputStream bis = excelReporteService.generateCsatExcel(data);

            reporteService.registrarGeneracion("CSAT_ANALISIS", "EXCEL", true, null, System.currentTimeMillis() - start,
                    null);

            HttpHeaders headers = new HttpHeaders();
            headers.add("Content-Disposition", "attachment; filename=csat_report.xlsx");

            return ResponseEntity
                    .ok()
                    .headers(headers)
                    .contentType(MediaType
                            .parseMediaType("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"))
                    .body(new InputStreamResource(bis));
        } catch (Exception e) {
            reporteService.registrarGeneracion("CSAT_FEEDBACK", "EXCEL", false, e.getMessage(),
                    System.currentTimeMillis() - start, null);
            throw e;
        }
    }

    @GetMapping("/data/sla-tecnico")
    @PreAuthorize("hasRole('ROLE_ADMIN_MASTER') or hasRole('ROLE_ADMIN_CONTRATOS') or hasRole('ROLE_ADMIN_TECNICOS')")
    public ResponseEntity<List<VwSlaTecnico>> getSlaTecnico() {
        return ResponseEntity.ok(reporteService.getSlaTecnicoData());
    }

    @GetMapping("/data/csat-analisis")
    @PreAuthorize("hasRole('ROLE_ADMIN_MASTER') or hasRole('ROLE_ADMIN_CONTRATOS') or hasRole('ROLE_ADMIN_TECNICOS')")
    public ResponseEntity<List<VwCsatAnalisis>> getCsatAnalisis() {
        return ResponseEntity.ok(reporteService.getCsatAnalisisData());
    }

    @GetMapping("/data/csat-detalle")
    @PreAuthorize("hasRole('ROLE_ADMIN_MASTER') or hasRole('ROLE_ADMIN_CONTRATOS') or hasRole('ROLE_ADMIN_TECNICOS')")
    public ResponseEntity<List<VwCsatDetalle>> getCsatDetalle() {
        return ResponseEntity.ok(reporteService.getCsatDetalleData());
    }
}
