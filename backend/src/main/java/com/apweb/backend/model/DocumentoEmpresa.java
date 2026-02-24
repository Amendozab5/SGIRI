package com.apweb.backend.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Entity
@Table(name = "documento_empresa", schema = "empresa")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class DocumentoEmpresa {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_documento")
    private Integer idDocumento;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id_empresa", nullable = false)
    private Empresa empresa;

    @Column(name = "numero_documento", length = 50, nullable = false)
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
    @JoinColumn(name = "id_tipo_documento", nullable = false)
    private TipoDocumento tipoDocumento;

    @PrePersist
    protected void onCreate() {
        this.fechaSubida = LocalDateTime.now();
    }
}
