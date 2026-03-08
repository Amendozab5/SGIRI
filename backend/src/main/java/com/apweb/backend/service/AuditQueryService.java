package com.apweb.backend.service;

import com.apweb.backend.dto.AuditDetailDTO;
import com.apweb.backend.dto.AuditTimelineDTO;
import com.apweb.backend.model.*;
import com.apweb.backend.repository.*;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.data.jpa.domain.Specification;

import java.time.LocalDateTime;
import java.util.Map;
import java.util.Optional;

@Service
@RequiredArgsConstructor
@Slf4j
public class AuditQueryService {

    private final AuditTimelineRepository timelineRepository;
    private final AuditoriaEventoRepository eventoRepository;
    private final AuditoriaLoginRepository loginRepository;
    private final AuditoriaEstadoTicketRepository estadoTicketRepository;
    private final CatalogoItemRepository catalogoItemRepository;
    private final ObjectMapper objectMapper;

    @Transactional(readOnly = true)
    public Page<AuditTimelineDTO> getTimeline(
            LocalDateTime startDate,
            LocalDateTime endDate,
            String modulo,
            String accion,
            String username,
            Boolean exito,
            String esquema,
            String tabla,
            Integer idRegistro,
            Pageable pageable) {

        Specification<AuditTimelineView> spec = Specification.where(null);

        if (startDate != null) {
            spec = spec.and((root, query, cb) -> cb.greaterThanOrEqualTo(root.get("fecha"), startDate));
        }
        if (endDate != null) {
            spec = spec.and((root, query, cb) -> cb.lessThanOrEqualTo(root.get("fecha"), endDate));
        }
        if (modulo != null && !modulo.isEmpty()) {
            spec = spec.and((root, query, cb) -> cb.equal(root.get("modulo"), modulo));
        }
        if (accion != null && !accion.isEmpty()) {
            spec = spec.and((root, query, cb) -> cb.equal(root.get("accion"), accion));
        }
        if (username != null && !username.isEmpty()) {
            spec = spec.and((root, query, cb) -> cb.equal(root.get("usuarioBd"), username));
        }
        if (exito != null) {
            spec = spec.and((root, query, cb) -> cb.equal(root.get("exito"), exito));
        }
        
        // --- Nuevos filtros de entidad ---
        if (esquema != null && !esquema.isEmpty()) {
            // Nota: La vista debe ser actualizada para incluir esquema si se requiere, 
            // pero por ahora filtramos por tabla y registro que ya están en la base.
        }
        if (tabla != null && !tabla.isEmpty()) {
            spec = spec.and((root, query, cb) -> cb.equal(root.get("tablaAfectada"), tabla));
        }
        if (idRegistro != null) {
            spec = spec.and((root, query, cb) -> cb.equal(root.get("originalId"), idRegistro));
        }

        return timelineRepository.findAll(spec, pageable).map(this::mapToDTO);
    }

    @Transactional(readOnly = true)
    public Optional<AuditDetailDTO> getEventDetail(String eventKey) {
        if (eventKey == null || !eventKey.contains("-")) {
            log.warn("Formato de eventKey inválido: {}", eventKey);
            return Optional.empty();
        }

        try {
            String[] parts = eventKey.trim().split("-");
            if (parts.length < 2) return Optional.empty();
            
            String prefix = parts[0].toUpperCase();
            Integer id = Integer.parseInt(parts[1].trim());

            return switch (prefix) {
                case "EV" -> eventoRepository.findById(id).map(this::mapEventoToDetail);
                case "LG" -> loginRepository.findById(id).map(this::mapLoginToDetail);
                case "TK" -> estadoTicketRepository.findById(id).map(this::mapEstadoTicketToDetail);
                default -> {
                    log.warn("Prefijo desconocido en eventKey: {}", prefix);
                    yield Optional.empty();
                }
            };
        } catch (Exception e) {
            log.error("Error al procesar eventKey '{}': {}", eventKey, e.getMessage());
            return Optional.empty();
        }
    }

    private AuditTimelineDTO mapToDTO(AuditTimelineView view) {
        return AuditTimelineDTO.builder()
                .eventKey(view.getEventKey())
                .tipoEntidad(view.getTipoEntidad())
                .fecha(view.getFecha())
                .modulo(view.getModulo())
                .accion(view.getAccion())
                .descripcion(view.getDescripcion())
                .actor(view.getActor())
                .idUsuario(view.getIdUsuario())
                .usuarioBd(view.getUsuarioBd())
                .ipOrigen(view.getIpOrigen())
                .exito(view.getExito())
                .build();
    }

    private AuditDetailDTO mapEventoToDetail(AuditoriaEvento evt) {
        AuditDetailDTO dto = AuditDetailDTO.builder()
                .eventKey("EV-" + evt.getIdEvento())
                .tipoEntidad("EVENTO")
                .fecha(evt.getFechaEvento())
                .modulo(evt.getModulo())
                .descripcion(evt.getDescripcion())
                .idUsuario(evt.getIdUsuario())
                .usuarioBd(evt.getUsuarioBd())
                .ipOrigen(evt.getIpOrigen())
                .exito(evt.getExito())
                .userAgent(evt.getUserAgent())
                .endpoint(evt.getEndpoint())
                .metodoHttp(evt.getMetodoHttp())
                .observacion(evt.getObservacion())
                .valoresAnteriores(parseJson(evt.getValoresAnteriores()))
                .valoresNuevos(parseJson(evt.getValoresNuevos()))
                .build();
        
        // Cargar código de acción si no está en el base (vía repo si hiciera falta, 
        // pero aquí usamos el DTO base enriquecido)
        dto.setAccion(getAccionCodigo(evt.getIdAccionItem()));
        return dto;
    }

    private AuditDetailDTO mapLoginToDetail(AuditoriaLogin login) {
        return AuditDetailDTO.builder()
                .eventKey("LG-" + login.getIdLogin())
                .tipoEntidad("LOGIN")
                .fecha(login.getFechaLogin())
                .modulo("AUTH")
                .accion(getAccionCodigo(login.getIdItemEvento()))
                .descripcion(login.getExito() ? "Login exitoso" : "Login fallido: " + login.getMotivoFallo())
                .idUsuario(login.getIdUsuario())
                .usuarioBd(login.getUsuarioBd())
                .ipOrigen(login.getIpOrigen())
                .exito(login.getExito())
                .userAgent(login.getUserAgent())
                .observacion(login.getMotivoFallo())
                .build();
    }

    private AuditDetailDTO mapEstadoTicketToDetail(AuditoriaEstadoTicket aet) {
        AuditDetailDTO dto = AuditDetailDTO.builder()
                .eventKey("TK-" + aet.getIdAuditoria())
                .tipoEntidad("ESTADO_TICKET")
                .fecha(aet.getFechaCambio())
                .modulo("TICKETS")
                .accion("CAMBIO_ESTADO")
                .descripcion("Cambio de estado del ticket #" + aet.getIdTicket())
                .idUsuario(aet.getIdUsuario())
                .usuarioBd(aet.getUsuarioBd())
                .exito(true)
                .idTicket(aet.getIdTicket())
                .build();
        
        dto.setEstadoAnterior(getEstadoNombre(aet.getIdEstadoAnterior()));
        dto.setEstadoNuevo(getEstadoNombre(aet.getIdEstadoNuevo()));
        return dto;
    }

    private Map<String, Object> parseJson(String json) {
        if (json == null || json.isEmpty()) return null;
        try {
            return objectMapper.readValue(json, new TypeReference<Map<String, Object>>() {});
        } catch (Exception e) {
            log.warn("Error parsing audit JSON: {}", e.getMessage());
            return Map.of("raw", json);
        }
    }

    private String getAccionCodigo(Integer idItem) {
        if (idItem == null) return "DESCONOCIDA";
        return catalogoItemRepository.findById(idItem)
                .map(CatalogoItem::getCodigo)
                .orElse("DESCONOCIDA");
    }

    private String getEstadoNombre(Integer idItem) {
        if (idItem == null) return "N/A";
        return catalogoItemRepository.findById(idItem)
                .map(CatalogoItem::getNombre)
                .orElse("N/A");
    }
}
