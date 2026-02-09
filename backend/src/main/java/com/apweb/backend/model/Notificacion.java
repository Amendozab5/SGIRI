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

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id_ticket") // Can be null
    private Ticket ticket;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id_usuario") // Can be null
    private User usuario;

    @Column(name = "id_tipo_notificacion")
    private Integer idTipoNotificacion; // Directly mapped as Integer

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id_usuario_origen") // Can be null
    private User usuarioOrigen; // Assuming it's a User

    @PrePersist
    protected void onCreate() {
        this.fechaCreacion = LocalDateTime.now();
    }
}
