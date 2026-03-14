package com.apweb.backend.service;

import com.apweb.backend.model.ConfiguracionReporte;
import com.apweb.backend.model.VwResumenTickets;
import com.apweb.backend.model.VwSlaTecnico;
import com.apweb.backend.model.VwCsatAnalisis;
import com.apweb.backend.model.VwCsatDetalle;
import com.apweb.backend.model.HistorialGeneracion;
import com.apweb.backend.repository.ConfiguracionReporteRepository;
import com.apweb.backend.repository.HistorialGeneracionRepository;
import com.apweb.backend.repository.VwResumenTicketsRepository;
import com.apweb.backend.repository.VwSlaTecnicoRepository;
import com.apweb.backend.repository.VwCsatAnalisisRepository;
import com.apweb.backend.repository.VwCsatDetalleRepository;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.time.LocalDateTime;

@Service
@RequiredArgsConstructor
public class ReporteService {

    private final ConfiguracionReporteRepository configRepo;
    private final HistorialGeneracionRepository historialRepo;
    private final VwResumenTicketsRepository resumenTicketsRepo;
    private final VwSlaTecnicoRepository slaRepo;
    private final VwCsatAnalisisRepository csatRepo;
    private final VwCsatDetalleRepository csatDetalleRepo;
    private final AuditService auditService;
    private final ObjectMapper objectMapper;

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

    /**
     * Registra un evento de generación de reporte en el historial.
     */
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void registrarGeneracion(String codigoReporte, String formato, boolean exito, String error, Long tiempoMs, Map<String, Object> params) {
        try {
            Optional<ConfiguracionReporte> config = configRepo.findByCodigoUnico(codigoReporte);
            if (config.isEmpty()) return;

            HistorialGeneracion h = new HistorialGeneracion();
            h.setReporte(config.get());
            h.setIdUsuario(auditService.resolveCurrentUserId());
            h.setTazaExito(exito);
            h.setMensajeError(error);
            h.setTiempoEjecucionMs(tiempoMs != null ? tiempoMs.intValue() : 0);
            h.setRutaArchivo(formato.toUpperCase()); // Usamos ruta_archivo para guardar el formato (PDF/EXCEL)
            
            if (params != null) {
                // Filtramos los nulos para que el JSON quede limpio
                Map<String, Object> filteredParams = params.entrySet().stream()
                        .filter(e -> e.getValue() != null)
                        .collect(java.util.stream.Collectors.toMap(Map.Entry::getKey, Map.Entry::getValue));
                
                if (!filteredParams.isEmpty()) {
                    h.setParametrosJson(objectMapper.writeValueAsString(filteredParams));
                }
            }

            historialRepo.save(h);
        } catch (Exception e) {
            // No bloqueamos la descarga por un error en auditoría
            e.printStackTrace();
        }
    }
}
