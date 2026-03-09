package com.apweb.backend.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import java.time.LocalDateTime;

@Entity
@Table(name = "configuracion_reporte", schema = "reportes")
@Getter
@Setter
public class ConfiguracionReporte {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer idReporte;

    @Column(nullable = false, length = 150)
    private String nombre;

    @Column(columnDefinition = "TEXT")
    private String descripcion;

    @Column(name = "codigo_unico", nullable = false, unique = true, length = 50)
    private String codigoUnico;

    @Column(nullable = false, length = 50)
    private String modulo;

    @Column(name = "tipo_salida", nullable = false, length = 20)
    private String tipoSalida;

    @Column(name = "es_activo")
    private Boolean esActivo = true;

    @Column(name = "fecha_creacion", updatable = false)
    private LocalDateTime fechaCreacion = LocalDateTime.now();
}
