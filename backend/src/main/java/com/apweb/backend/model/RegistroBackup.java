package com.apweb.backend.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDateTime;

@Entity
@Table(name = "registro_backup", schema = "reportes")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class RegistroBackup {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @Column(nullable = false, updatable = false)
    private LocalDateTime fecha;

    @Column(name = "nombre_archivo", length = 150)
    private String nombreArchivo;

    @Column(name = "url_cloudinary", columnDefinition = "TEXT")
    private String urlCloudinary;

    @Column(name = "tamano_bytes")
    private Long tamanoBytes;

    @Enumerated(EnumType.STRING)
    @Column(length = 20, nullable = false)
    private TipoBackup tipo;

    @Enumerated(EnumType.STRING)
    @Column(length = 20, nullable = false)
    private EstadoBackup estado;

    @Column(columnDefinition = "TEXT")
    private String error;

    public enum TipoBackup {
        MANUAL, AUTOMATICO
    }

    public enum EstadoBackup {
        EXITOSO, FALLIDO
    }

    @PrePersist
    protected void onCreate() {
        this.fecha = LocalDateTime.now();
    }
}
