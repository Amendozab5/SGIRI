package com.apweb.backend.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;
import org.hibernate.annotations.Immutable;
import java.math.BigDecimal;

@Entity
@Immutable
@Table(name = "vw_sla_tecnico", schema = "reportes")
@Getter
public class VwSlaTecnico {

    @Id
    @Column(name = "id_usuario")
    private Integer idUsuario;

    @Column(name = "tecnico_nombre")
    private String tecnicoNombre;

    @Column(name = "total_tickets")
    private Long totalTickets;

    @Column(name = "tickets_resueltos")
    private Long ticketsResueltos;

    @Column(name = "sla_cumplido")
    private Long slaCumplido;

    @Column(name = "avg_resolucion_horas")
    private BigDecimal avgResolucionHoras;
}
