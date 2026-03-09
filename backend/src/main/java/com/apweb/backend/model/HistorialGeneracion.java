package com.apweb.backend.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import java.time.LocalDateTime;

@Entity
@Table(name = "historial_generacion", schema = "reportes")
@Getter
@Setter
public class HistorialGeneracion {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer idGeneracion;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id_reporte", nullable = false)
    private ConfiguracionReporte reporte;

    @Column(name = "id_usuario", nullable = false)
    private Integer idUsuario;

    @Column(name = "parametros_json", columnDefinition = "JSONB")
    private String parametrosJson;

    @Column(name = "ruta_archivo", columnDefinition = "TEXT")
    private String rutaArchivo;

    @Column(name = "taza_exito")
    private Boolean tazaExito = true;

    @Column(name = "mensaje_error", columnDefinition = "TEXT")
    private String mensajeError;

    @Column(name = "tiempo_ejecucion_ms")
    private Integer tiempoEjecucionMs;

    @Column(name = "fecha_generacion")
    private LocalDateTime fechaGeneracion = LocalDateTime.now();
}
