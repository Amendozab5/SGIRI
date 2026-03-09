package com.apweb.backend.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;
import org.hibernate.annotations.Immutable;
import java.time.LocalDateTime;

@Entity
@Immutable
@Table(name = "vw_resumen_tickets", schema = "reportes")
@Getter
public class VwResumenTickets {

    @Id
    @Column(name = "id_ticket")
    private Integer idTicket;

    private String asunto;

    @Column(name = "fecha_creacion")
    private LocalDateTime fechaCreacion;

    @Column(name = "fecha_cierre")
    private LocalDateTime fechaCierre;

    private String estado;

    @Column(name = "estado_codigo")
    private String estadoCodigo;

    private String prioridad;

    @Column(name = "tiempo_resolucion")
    private String tiempoResolucion;

    @Column(name = "calificacion_satisfaccion")
    private Integer calificacionSatisfaccion;

    @Column(name = "id_usuario_asignado")
    private Integer idUsuarioAsignado;

    @Column(name = "id_cliente")
    private Integer idCliente;

    @Column(name = "id_sucursal")
    private Integer idSucursal;

    @Column(name = "id_categoria_item")
    private Integer idCategoriaItem;

    private String categoria;
}
