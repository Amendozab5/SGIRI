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
@Table(name = "vw_csat_detalle", schema = "reportes")
@Getter
public class VwCsatDetalle {

    @Id
    @Column(name = "id_ticket")
    private Integer idTicket;

    private String asunto;

    @Column(name = "fecha_creacion")
    private LocalDateTime fechaCreacion;

    @Column(name = "fecha_cierre")
    private LocalDateTime fechaCierre;

    @Column(name = "calificacion_satisfaccion")
    private Integer calificacionSatisfaccion;

    @Column(name = "comentario_calificacion")
    private String comentarioCalificacion;

    @Column(name = "cliente_nombre")
    private String clienteNombre;

    private String categoria;
}
