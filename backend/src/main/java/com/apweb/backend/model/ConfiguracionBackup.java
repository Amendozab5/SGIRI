package com.apweb.backend.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalTime;

@Entity
@Table(name = "configuracion_backup", schema = "reportes")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ConfiguracionBackup {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @Builder.Default
    @Column(nullable = false)
    private Boolean activo = false;

    @Builder.Default
    @Enumerated(EnumType.STRING)
    @Column(length = 20, nullable = false)
    private Frecuencia frecuencia = Frecuencia.DIARIA;

    @Builder.Default
    @Column(name = "hora_ejecucion", nullable = false)
    private LocalTime horaEjecucion = LocalTime.of(3, 0); // Por defecto 3 AM

    @Builder.Default
    @Column(name = "retencion_dias")
    private Integer retencionDias = 7; // Mantener localmente por 7 días

    @Column(name = "ultimo_nombre_backup")
    private String ultimoNombreBackup;

    public enum Frecuencia {
        DIARIA, SEMANAL, MENSUAL
    }
}
