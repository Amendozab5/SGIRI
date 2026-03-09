package com.apweb.backend.service;

import com.apweb.backend.model.ConfiguracionReporte;
import com.apweb.backend.model.VwResumenTickets;
import com.apweb.backend.model.VwSlaTecnico;
import com.apweb.backend.model.VwCsatAnalisis;
import com.apweb.backend.model.VwCsatDetalle;
import com.apweb.backend.repository.ConfiguracionReporteRepository;
import com.apweb.backend.repository.VwResumenTicketsRepository;
import com.apweb.backend.repository.VwSlaTecnicoRepository;
import com.apweb.backend.repository.VwCsatAnalisisRepository;
import com.apweb.backend.repository.VwCsatDetalleRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import java.util.List;
import java.util.Optional;
import java.time.LocalDateTime;

@Service
@RequiredArgsConstructor
public class ReporteService {

    private final ConfiguracionReporteRepository configRepo;
    private final VwResumenTicketsRepository resumenTicketsRepo;
    private final VwSlaTecnicoRepository slaRepo;
    private final VwCsatAnalisisRepository csatRepo;
    private final VwCsatDetalleRepository csatDetalleRepo;

    /**
     * Obtiene todos los reportes configurados activos.
     */
    public List<ConfiguracionReporte> getReportesDisponibles() {
        return configRepo.findAll().stream()
                .filter(ConfiguracionReporte::getEsActivo)
                .toList();
    }

    /**
     * Obtiene la configuración de un reporte por su código único.
     */
    public Optional<ConfiguracionReporte> getReporteByCodigo(String codigo) {
        return configRepo.findByCodigoUnico(codigo);
    }

    /**
     * Obtiene datos para el reporte de tickets, con filtros técnicos y de fecha
     * opcionales.
     */
    public List<VwResumenTickets> getTicketsData(Integer idTecnico, String status, String search, LocalDateTime desde,
            LocalDateTime hasta) {
        return resumenTicketsRepo.findAll().stream()
                .filter(t -> idTecnico == null || idTecnico.equals(t.getIdUsuarioAsignado()))
                .filter(t -> status == null || status.equals("TODOS") ||
                        (t.getEstadoCodigo() != null && t.getEstadoCodigo().equalsIgnoreCase(status)) ||
                        (t.getEstado() != null && t.getEstado().equalsIgnoreCase(status)))
                .filter(t -> search == null || search.isEmpty() ||
                        (t.getAsunto() != null && t.getAsunto().toLowerCase().contains(search.toLowerCase())) ||
                        (t.getIdTicket() != null && t.getIdTicket().toString().contains(search)))
                .filter(t -> desde == null || (t.getFechaCreacion() != null && t.getFechaCreacion().isAfter(desde)))
                .filter(t -> hasta == null || (t.getFechaCreacion() != null && t.getFechaCreacion().isBefore(hasta)))
                .toList();
    }

    /**
     * Obtiene datos consolidados de SLA por técnico.
     */
    public List<VwSlaTecnico> getSlaTecnicoData() {
        return slaRepo.findAll();
    }

    /**
     * Obtiene datos de análisis de satisfacción CSAT (Agregado por mes).
     */
    public List<VwCsatAnalisis> getCsatAnalisisData() {
        return csatRepo.findAll();
    }

    /**
     * Obtiene el detalle individual de satisfacción (Comentarios).
     */
    public List<VwCsatDetalle> getCsatDetalleData() {
        return csatDetalleRepo.findAll();
    }
}
