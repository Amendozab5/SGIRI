package com.apweb.backend.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * Entidad JPA mapeada a {@code auditoria.auditoria_login}.
 * <p>
 * Registra cada intento de autenticación al sistema, tanto exitosos como fallidos.
 * La columna {@code exito} distingue entre ambos casos.
 * </p>
 */
@Entity
@Table(name = "auditoria_login", schema = "auditoria")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AuditoriaLogin {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_login")
    private Integer idLogin;

    // ── Identidad ─────────────────────────────────────────────────────────────

    /** Username de la aplicación intentado (puede no existir en tabla si es intento fallido) */
    @Column(name = "usuario_app", length = 100)
    private String usuarioApp;

    /** Rol físico PostgreSQL (emp_cedula_id). Null si el usuario no existe o es CLIENTE */
    @Column(name = "usuario_bd", length = 100)
    private String usuarioBd;

    /** ID del usuario si fue encontrado. Null si el username no existe en BD */
    @Column(name = "id_usuario")
    private Integer idUsuario;

    // ── Resultado ─────────────────────────────────────────────────────────────

    /** true = login exitoso; false = intento fallido */
    @Column(name = "exito", nullable = false)
    private Boolean exito;

    /**
     * Descripción del motivo de fallo cuando {@code exito = false}.
     * Ejemplos: "Credenciales incorrectas", "Cuenta inactiva/bloqueada".
     * Null cuando el login es exitoso.
     */
    @Column(name = "motivo_fallo", length = 200)
    private String motivoFallo;

    // ── Contexto HTTP ─────────────────────────────────────────────────────────

    /** IP de origen. Considera header X-Forwarded-For si existe (proxy/load balancer) */
    @Column(name = "ip_origen", length = 45)
    private String ipOrigen;

    /** User-Agent del navegador o cliente HTTP usado en el intento */
    @Column(name = "user_agent", columnDefinition = "TEXT")
    private String userAgent;

    // ── Catálogo ──────────────────────────────────────────────────────────────

    /**
     * FK al catálogo ACCION_AUDITORIA.
     * Para login exitoso: id del ítem con código LOGIN.
     * Para login fallido: id del ítem con código LOGIN_FALLIDO.
     */
    @Column(name = "id_item_evento")
    private Integer idItemEvento;

    // ── Cuándo ────────────────────────────────────────────────────────────────

    @Column(name = "fecha_login", updatable = false)
    private LocalDateTime fechaLogin;

    @PrePersist
    protected void onCreate() {
        if (this.fechaLogin == null) {
            this.fechaLogin = LocalDateTime.now();
        }
    }
}
