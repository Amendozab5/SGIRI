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
@com.fasterxml.jackson.annotation.JsonIgnoreProperties({ "hibernateLazyInitializer", "handler" })
public class DocumentoTicket {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_documento")
    private Integer idDocumento;

    @com.fasterxml.jackson.annotation.JsonIgnore
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id_ticket", nullable = false)
    private Ticket ticket;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id_tipo_documento_item", nullable = false)
    private CatalogoItem tipoDocumento;

    @Column(name = "nombre_archivo", length = 255, nullable = false)
    private String nombreArchivo;

    @Column(name = "ruta_archivo", columnDefinition = "TEXT", nullable = false)
    private String rutaArchivo;

    @Column(columnDefinition = "TEXT")
    private String descripcion;

    @Column(name = "fecha_subida", updatable = false)
    private LocalDateTime fechaSubida;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id_usuario_subio", nullable = false)
    private User usuario;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id_estado_item", nullable = false)
    private CatalogoItem estado;

    @PrePersist
    protected void onCreate() {
        this.fechaSubida = LocalDateTime.now();
    }
}
