package com.apweb.backend.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.experimental.SuperBuilder;

import java.time.LocalDateTime;

/**
 * DTO para el listado resumido de la línea de tiempo de auditoría.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@SuperBuilder
public class AuditTimelineDTO {
    private String eventKey;      // EV-1, LG-2, TK-3
    private String tipoEntidad;   // EVENTO, LOGIN, ESTADO_TICKET
    private LocalDateTime fecha;
    private String modulo;
    private String accion;
    private String descripcion;
    private String actor;         // Nombre humanamente legible (username aplicativo)
    private Integer idUsuario;
    private String usuarioBd;
    private String ipOrigen;
    private Boolean exito;
}
