package com.apweb.backend.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.time.LocalDateTime;

/**
 * Entidad JPA mapeada a {@code auditoria.auditoria_evento}.
 * <p>
 * Registra eventos genéricos de auditoría: INSERT, UPDATE, DELETE sobre
 * cualquier módulo del sistema. También cubre eventos no-CRUD como COMENTARIO,
 * CALIFICACION, UPLOAD_DOCUMENTO, etc.
 * </p>
 *
 * <p><strong>Relaciones JPA:</strong> Se usan campos primitivos/String en lugar
 * de relaciones {@code @ManyToOne} para evitar ciclos de carga y simplificar
 * el aislamiento de la capa de auditoría.</p>
 */
@Entity
@Table(name = "auditoria_evento", schema = "auditoria")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AuditoriaEvento {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_evento")
    private Integer idEvento;

    // ── Qué entidad fue afectada ───────────────────────────────────────────────

    /** Área funcional: TICKETS, USUARIOS, VISITAS, DOCUMENTOS, AUTH, EMPLEADOS, PERFIL */
    @Column(name = "modulo", length = 50)
    private String modulo;

    /** Schema PostgreSQL donde vive la tabla afectada (ej. "soporte", "usuarios") */
    @Column(name = "esquema_afectado", length = 50, nullable = false)
    private String esquemaAfectado;

    /** Nombre de la tabla afectada (ej. "ticket", "usuario") */
    @Column(name = "tabla_afectada", length = 50, nullable = false)
    private String tablaAfectada;

    /** ID (PK) del registro concreto que fue afectado */
    @Column(name = "id_registro", nullable = false)
    private Integer idRegistro;

    // ── Qué ocurrió ───────────────────────────────────────────────────────────

    /** Descripción breve legible del evento (ej. "Cambio de estado a ASIGNADO") */
    @Column(name = "descripcion", columnDefinition = "TEXT")
    private String descripcion;

    /**
     * Estado anterior del registro serializado como JSON String.
     * Solo aplica para UPDATE y DELETE. Null en INSERT.
     * Ejemplo: {"estado": "ABIERTO", "prioridad": "BAJA"}
     */
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "valores_anteriores")
    private String valoresAnteriores;

    /**
     * Estado nuevo del registro serializado como JSON String.
     * Solo aplica para INSERT y UPDATE. Null en DELETE.
     * Ejemplo: {"estado": "ASIGNADO", "idTecnico": 12}
     */
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "valores_nuevos")
    private String valoresNuevos;

    /**
     * Observación adicional de contexto. Texto libre.
     * Útil para registrar mensajes de error en caso de exito=false.
     */
    @Column(name = "observacion", columnDefinition = "TEXT")
    private String observacion;

    /** true = operación exitosa; false = operación intentada pero fallida */
    @Column(name = "exito", nullable = false)
    @Builder.Default
    private Boolean exito = true;

    // ── Quién ejecutó la acción ───────────────────────────────────────────────

    /** Rol físico de PostgreSQL (emp_cedula_id) o usuario técnico (sgiri_app) */
    @Column(name = "usuario_bd", length = 100, nullable = false)
    private String usuarioBd;

    /** Rol BD que estaba activo (ej. rol_tecnico, rol_admin_master) */
    @Column(name = "rol_bd", length = 100, nullable = false)
    private String rolBd;

    /** ID del usuario de la aplicación. Puede ser null si no autenticado */
    @Column(name = "id_usuario")
    private Integer idUsuario;

    // ── Contexto HTTP de la petición ──────────────────────────────────────────

    /** Dirección IP del cliente (IPv4 o IPv6). Considera X-Forwarded-For */
    @Column(name = "ip_origen", length = 45)
    private String ipOrigen;

    /** User-Agent del navegador/cliente HTTP */
    @Column(name = "user_agent", columnDefinition = "TEXT")
    private String userAgent;

    /** Endpoint REST invocado (ej. /api/tickets/5/status) */
    @Column(name = "endpoint", length = 200)
    private String endpoint;

    /** Método HTTP: GET, POST, PUT, DELETE, PATCH */
    @Column(name = "metodo_http", length = 10)
    private String metodoHttp;

    // ── Catálogo de acción ────────────────────────────────────────────────────

    /**
     * FK al catálogo ACCION_AUDITORIA (id_catalogo=8).
     * Se guarda solo el ID para evitar JOIN en escritura.
     * Uso: buscar el id_item por código en CatalogoItemRepository antes de persistir.
     */
    @Column(name = "id_accion_item", nullable = false)
    private Integer idAccionItem;

    /**
     * FK opcional a notificación relacionada (columna existente en el schema).
     * No se usa actualmente — mantenida para compatibilidad con el DDL original.
     */
    @Column(name = "id_notificacion")
    private Integer idNotificacion;

    // ── Cuándo ────────────────────────────────────────────────────────────────

    @Column(name = "fecha_evento", updatable = false)
    private LocalDateTime fechaEvento;

    @PrePersist
    protected void onCreate() {
        if (this.fechaEvento == null) {
            this.fechaEvento = LocalDateTime.now();
        }
    }
}
