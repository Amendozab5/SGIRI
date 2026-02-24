package com.apweb.backend.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Entity
@Table(name = "ticket", schema = "soporte")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@com.fasterxml.jackson.annotation.JsonIgnoreProperties({ "hibernateLazyInitializer", "handler" })
public class Ticket {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_ticket")
    private Integer idTicket;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id_cliente", nullable = false)
    private Cliente cliente;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id_usuario_creador")
    private User usuarioCreador;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id_usuario_asignado")
    private User usuarioAsignado;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id_sucursal", nullable = false)
    private Sucursal sucursal;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id_servicio", nullable = false)
    private Servicio servicio;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id_sla")
    private SlaTicket sla;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id_categoria_item", nullable = false)
    private CatalogoItem categoriaItem;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id_prioridad_item", nullable = false)
    private CatalogoItem prioridadItem;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id_estado_item", nullable = false)
    private CatalogoItem estadoItem;

    @Column(length = 200, nullable = false)
    private String asunto;

    @Column(nullable = false, columnDefinition = "TEXT")
    private String descripcion;

    @Column(name = "fecha_creacion", updatable = false)
    private LocalDateTime fechaCreacion;

    @Column(name = "fecha_actualizacion")
    private LocalDateTime fechaActualizacion;

    @Column(name = "fecha_cierre")
    private LocalDateTime fechaCierre;

    @com.fasterxml.jackson.annotation.JsonIgnore
    @OneToMany(mappedBy = "ticket", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private java.util.List<Asignacion> asignaciones;

    @OneToMany(mappedBy = "ticket", cascade = CascadeType.ALL, fetch = FetchType.EAGER)
    private java.util.List<ComentarioTicket> comentarios;

    @com.fasterxml.jackson.annotation.JsonIgnore
    @OneToMany(mappedBy = "ticket", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private java.util.List<DocumentoTicket> documentos;

    @OneToMany(mappedBy = "ticket", cascade = CascadeType.ALL, fetch = FetchType.EAGER)
    private java.util.List<HistorialEstado> historialEstados;

    @com.fasterxml.jackson.annotation.JsonIgnore
    @OneToMany(mappedBy = "ticket", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private java.util.List<Notificacion> notificaciones;

    @PrePersist
    protected void onCreate() {
        this.fechaCreacion = LocalDateTime.now();
    }

    @PreUpdate
    protected void onUpdate() {
        this.fechaActualizacion = LocalDateTime.now();
    }
}
