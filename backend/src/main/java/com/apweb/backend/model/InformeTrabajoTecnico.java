package com.apweb.backend.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Entity
@Table(name = "informe_trabajo_tecnico", schema = "soporte")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@com.fasterxml.jackson.annotation.JsonIgnoreProperties({ "hibernateLazyInitializer", "handler" })
@org.hibernate.annotations.DynamicUpdate
public class InformeTrabajoTecnico {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_informe")
    private Integer idInforme;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id_ticket", nullable = false)
    @com.fasterxml.jackson.annotation.JsonIgnore
    private Ticket ticket;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id_tecnico", nullable = false)
    private User tecnico;

    @Column(length = 20, nullable = false)
    private String resultado;

    @Column(name = "implementos_usados", columnDefinition = "TEXT")
    private String implementosUsados;

    @Column(name = "problemas_encontrados", columnDefinition = "TEXT")
    private String problemasEncontrados;

    @Column(name = "solucion_aplicada", columnDefinition = "TEXT")
    private String solucionAplicada;

    @Column(name = "pruebas_realizadas", columnDefinition = "TEXT")
    private String pruebasRealizadas;

    @Column(name = "motivo_no_resolucion", columnDefinition = "TEXT")
    private String motivoNoResolucion;

    @Column(name = "comentario_tecnico", columnDefinition = "TEXT")
    private String comentarioTecnico;

    @Column(name = "url_adjunto", columnDefinition = "TEXT")
    private String urlAdjunto;

    @Column(name = "tiempo_trabajo_minutos")
    private Integer tiempoTrabajoMinutos;

    @Column(name = "fecha_registro", updatable = false)
    private LocalDateTime fechaRegistro;

    @PrePersist
    protected void onCreate() {
        this.fechaRegistro = LocalDateTime.now();
    }
}
