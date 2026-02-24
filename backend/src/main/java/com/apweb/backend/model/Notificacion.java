package com.apweb.backend.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Entity
@Table(name = "notificacion", schema = "notificaciones")
@Data
@NoArgsConstructor
@AllArgsConstructor
@com.fasterxml.jackson.annotation.JsonIgnoreProperties({ "hibernateLazyInitializer", "handler" })
public class Notificacion {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_notificacion")
    private Integer idNotificacion;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id_canal", nullable = false)
    private CanalNotificacion canal;

    @Column(length = 150, nullable = false)
    private String destinatario;

    @Column(length = 150)
    private String asunto;

    @Column(columnDefinition = "TEXT", nullable = false)
    private String mensaje;

    private Boolean enviado;

    @Column(name = "fecha_creacion", updatable = false)
    private LocalDateTime fechaCreacion;

    @com.fasterxml.jackson.annotation.JsonIgnore
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id_ticket") // Can be null
    private Ticket ticket;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id_usuario_destino") // Mapping to id_usuario_destino
    private User usuarioDestino;

    @Column(name = "id_tipo_notificacion")
    private Integer idTipoNotificacion;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id_usuario_origen")
    private User usuarioOrigen;

    @Column(name = "id_empresa", nullable = false)
    private Integer idEmpresa;

    @Column(name = "fecha_envio")
    private LocalDateTime fechaEnvio;

    @Column(name = "error_envio", columnDefinition = "TEXT")
    private String errorEnvio;

    @PrePersist
    protected void onCreate() {
        this.fechaCreacion = LocalDateTime.now();
    }
}
