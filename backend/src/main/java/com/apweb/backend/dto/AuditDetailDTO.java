package com.apweb.backend.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.experimental.SuperBuilder;

import java.util.Map;

import lombok.EqualsAndHashCode;

/**
 * DTO detallado para un evento de auditoría específico.
 */
@Data
@EqualsAndHashCode(callSuper = true)
@NoArgsConstructor
@AllArgsConstructor
@SuperBuilder
public class AuditDetailDTO extends AuditTimelineDTO {
    private String userAgent;
    private String endpoint;
    private String metodoHttp;
    private Map<String, Object> valoresAnteriores;
    private Map<String, Object> valoresNuevos;
    private String observacion;
    
    // Para detalles de ticket
    private Integer idTicket;
    private String estadoAnterior;
    private String estadoNuevo;
}
