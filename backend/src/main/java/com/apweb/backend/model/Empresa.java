package com.apweb.backend.model;

import jakarta.persistence.*;
import lombok.Data;
import java.time.LocalDateTime;

@Entity
@Table(name = "empresa", schema = "empresa")
@Data
@com.fasterxml.jackson.annotation.JsonIgnoreProperties({ "hibernateLazyInitializer", "handler" })
public class Empresa {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_empresa")
    private Integer id;

    @Column(name = "nombre_comercial", length = 100, nullable = false)
    private String nombreComercial;

    @Column(name = "razon_social", length = 150, nullable = false)
    private String razonSocial;

    @Column(length = 13, nullable = false, unique = true)
    private String ruc;

    @Column(name = "tipo_empresa", length = 30, nullable = false)
    private String tipoEmpresa;

    @Column(name = "id_catalogo_item_tipo_empresa")
    private Integer idTipoEmpresaItem;

    @Column(name = "correo_contacto", length = 150)
    private String correoContacto;

    @Column(name = "telefono_contacto", length = 20)
    private String telefonoContacto;

    @Column(name = "direccion_principal", columnDefinition = "TEXT")
    private String direccionPrincipal;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "id_catalogo_item_estado")
    private CatalogoItem estado;

    @Column(name = "fecha_creacion", updatable = false)
    private LocalDateTime fechaCreacion;

    @com.fasterxml.jackson.annotation.JsonIgnore
    @OneToMany(mappedBy = "empresa", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private java.util.List<DocumentoEmpresa> documentos;

    @com.fasterxml.jackson.annotation.JsonIgnore
    @ManyToMany
    @JoinTable(name = "empresa_servicio", schema = "empresa", joinColumns = @JoinColumn(name = "id_empresa"), inverseJoinColumns = @JoinColumn(name = "id_servicio"))
    private java.util.Set<Servicio> servicios;

}
