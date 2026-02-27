package com.apweb.backend.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Entity
@Table(name = "sla_ticket", schema = "soporte")
@Data
@NoArgsConstructor
@AllArgsConstructor
@com.fasterxml.jackson.annotation.JsonIgnoreProperties({ "hibernateLazyInitializer", "handler" })
public class SlaTicket {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_sla")
    private Integer id;

    @Column(length = 100, nullable = false)
    private String nombre;

    @Column(columnDefinition = "TEXT")
    private String descripcion;

    @Column(name = "tiempo_respuesta_min", nullable = false)
    private Integer tiempoRespuestaMin;

    @Column(name = "tiempo_solucion_min", nullable = false)
    private Integer tiempoSolucionMin;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "aplica_prioridad") // Can be null
    private CatalogoItem aplicaPrioridad; // Foreign key to catalogo_item

    private Boolean activo;

    @Column(name = "fecha_creacion", updatable = false)
    private LocalDateTime fechaCreacion;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id_empresa", nullable = false)
    private Empresa empresa;
}
