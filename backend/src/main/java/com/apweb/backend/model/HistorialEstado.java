package com.apweb.backend.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Entity
@Table(name = "historial_estado", schema = "soporte")
@Data
@NoArgsConstructor
@AllArgsConstructor
@com.fasterxml.jackson.annotation.JsonIgnoreProperties({ "hibernateLazyInitializer", "handler" })
public class HistorialEstado {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_historial")
    private Integer idHistorial;

    @com.fasterxml.jackson.annotation.JsonIgnore
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id_ticket", nullable = false)
    private Ticket ticket;

    // This refers to the current state, mapping to CatalogoItem directly
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id_estado", nullable = false)
    private CatalogoItem estado;

    @Column(name = "usuario_bd", length = 100, nullable = false)
    private String usuarioBd;

    @Column(name = "fecha_cambio", updatable = false)
    private LocalDateTime fechaCambio;

    @Column(columnDefinition = "TEXT")
    private String observacion;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id_estado_anterior") // Can be null
    private CatalogoItem estadoAnterior;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id_estado_nuevo", nullable = false)
    private CatalogoItem estadoNuevo;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id_usuario") // Can be null
    private User usuario;

    @PrePersist
    protected void onCreate() {
        this.fechaCambio = LocalDateTime.now();
    }
}
