package com.apweb.backend.model;

import jakarta.persistence.*;
import lombok.Data;
import java.time.LocalDateTime;

@Entity
@Table(name = "empresa", schema = "empresa")
@Data
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

    @Column(name = "correo_contacto", length = 150)
    private String correoContacto;

    @Column(name = "telefono_contacto", length = 20)
    private String telefonoContacto;

    @Column(name = "direccion_principal")
    private String direccionPrincipal;

    @Column(length = 20, nullable = false)
    private String estado;

    @Column(name = "fecha_creacion", updatable = false)
    private LocalDateTime fechaCreacion;

    @OneToMany(mappedBy = "empresa", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private java.util.List<DocumentoEmpresa> documentos;

    @ManyToMany
    @JoinTable(
        name = "empresa_servicio",
        schema = "empresa",
        joinColumns = @JoinColumn(name = "id_empresa"),
        inverseJoinColumns = @JoinColumn(name = "id_servicio")
    )
    private java.util.Set<Servicio> servicios;


}
