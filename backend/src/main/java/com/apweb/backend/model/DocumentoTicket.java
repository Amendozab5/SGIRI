package com.apweb.backend.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Entity
@Table(name = "documento_ticket", schema = "soporte")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class DocumentoTicket {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_documento")
    private Integer idDocumento;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id_ticket", nullable = false)
    private Ticket ticket;

    @Column(name = "tipo_documento", length = 50, nullable = false)
    private String tipoDocumento;

    @Column(name = "ruta_archivo", columnDefinition = "TEXT", nullable = false)
    private String rutaArchivo;

    @Column(columnDefinition = "TEXT")
    private String descripcion;

    @Column(name = "fecha_subida", updatable = false)
    private LocalDateTime fechaSubida;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id_usuario") // Can be null
    private User usuario;

    @PrePersist
    protected void onCreate() {
        this.fechaSubida = LocalDateTime.now();
    }
}
