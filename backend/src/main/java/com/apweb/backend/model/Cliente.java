package com.apweb.backend.model;

import jakarta.persistence.*;
import lombok.Data;
import java.time.LocalDate;

@Entity
@Table(name = "cliente", schema = "clientes")
@Data
@com.fasterxml.jackson.annotation.JsonIgnoreProperties({ "hibernateLazyInitializer", "handler" })
public class Cliente {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_cliente")
    private Integer idCliente;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id_sucursal")
    private Sucursal sucursal;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id_persona")
    private Persona persona;

    @Column(name = "fecha_inicio_contrato")
    private LocalDate fechaInicioContrato;

    @Column(name = "fecha_fin_contrato")
    private LocalDate fechaFinContrato;

    @Column(name = "acceso_remoto")
    private Boolean accesoRemoto;

    @Column(name = "aprobacion_de_cambios")
    private Boolean aprobacionDeCambios;

    @Column(name = "actualizaciones_automaticas")
    private Boolean actualizacionesAutomaticas;

    @com.fasterxml.jackson.annotation.JsonIgnore
    @OneToMany(mappedBy = "cliente", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private java.util.List<DocumentoCliente> documentos;
}
