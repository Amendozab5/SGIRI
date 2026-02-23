package com.apweb.backend.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Entity
@Table(name = "documento_cliente", schema = "clientes")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class DocumentoCliente {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_documento")
    private Integer idDocumento;

    @Column(name = "numero_documento", length = 10, nullable = false)
    private String numeroDocumento;

    @Column(name = "ruta_archivo", columnDefinition = "TEXT", nullable = false)
    private String rutaArchivo;

    @Column(columnDefinition = "TEXT")
    private String descripcion;

    @Column(name = "fecha_subida", updatable = false)
    private LocalDateTime fechaSubida;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id_catalogo_item_estado")
    private CatalogoItem estado;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id_cliente", nullable = false)
    private Cliente cliente;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id_tipo_documento", nullable = false)
    private TipoDocumento tipoDocumento;

    @PrePersist
    protected void onCreate() {
        this.fechaSubida = LocalDateTime.now();
    }
}
