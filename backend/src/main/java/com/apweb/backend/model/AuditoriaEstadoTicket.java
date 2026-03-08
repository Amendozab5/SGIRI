package com.apweb.backend.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * Entidad JPA mapeada a {@code auditoria.auditoria_estado_ticket}.
 * <p>
 * Registro especializado de auditoría para cambios de estado en el ciclo de vida
 * del ticket. Complementa (sin reemplazar) a {@code soporte.historial_estado}:
 * </p>
 * <ul>
 *   <li>{@code soporte.historial_estado} → trazabilidad funcional del negocio, vista por técnicos/clientes</li>
 *   <li>{@code auditoria.auditoria_estado_ticket} → trazabilidad administrativa/seguridad, para auditoría</li>
 * </ul>
 */
@Entity
@Table(name = "auditoria_estado_ticket", schema = "auditoria")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AuditoriaEstadoTicket {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_auditoria")
    private Integer idAuditoria;

    // ── Referencia al ticket ───────────────────────────────────────────────────

    /** ID del ticket afectado (FK lógica a soporte.ticket — no declarada como @ManyToOne) */
    @Column(name = "id_ticket", nullable = false)
    private Integer idTicket;

    // ── Estados (IDs de catálogo_item) ────────────────────────────────────────

    /** id_item del estado anterior. Null si es el registro inicial (creación del ticket) */
    @Column(name = "id_estado_anterior")
    private Integer idEstadoAnterior;

    /** id_item del nuevo estado activo tras el cambio */
    @Column(name = "id_estado_nuevo_item")
    private Integer idEstadoNuevo;

    // ── Acción del catálogo ───────────────────────────────────────────────────

    /**
     * FK al catálogo ACCION_AUDITORIA.
     * Normalmente corresponde al ítem con código CAMBIO_ESTADO.
     */
    @Column(name = "id_item_evento")
    private Integer idItemEvento;

    // ── Quién ejecutó el cambio ───────────────────────────────────────────────

    /** Rol físico PostgreSQL del usuario que realizó el cambio */
    @Column(name = "usuario_bd", length = 100, nullable = false)
    private String usuarioBd;

    /** ID del usuario de la aplicación que realizó el cambio */
    @Column(name = "id_usuario")
    private Integer idUsuario;

    // ── Cuándo ────────────────────────────────────────────────────────────────

    @Column(name = "fecha_cambio", updatable = false)
    private LocalDateTime fechaCambio;

    @PrePersist
    protected void onCreate() {
        if (this.fechaCambio == null) {
            this.fechaCambio = LocalDateTime.now();
        }
    }
}
