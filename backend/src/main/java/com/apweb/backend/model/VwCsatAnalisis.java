package com.apweb.backend.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;
import org.hibernate.annotations.Immutable;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Immutable
@Table(name = "vw_csat_analisis", schema = "reportes")
@Getter
public class VwCsatAnalisis {

    @Id
    private LocalDateTime mes;

    @Column(name = "total_respuestas")
    private Long totalRespuestas;

    @Column(name = "puntaje_promedio")
    private BigDecimal puntajePromedio;

    @Column(name = "tasa_positiva")
    private BigDecimal tasaPositiva;
}
