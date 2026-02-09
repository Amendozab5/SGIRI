package com.apweb.backend.model;

import jakarta.persistence.*;
import lombok.Data;
import java.time.LocalDateTime;

@Entity
@Table(name = "cliente", schema = "clientes")
@Data
public class Cliente {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_cliente")
    private Integer idCliente;

    @Column(length = 10, nullable = false, unique = true)
    private String cedula;

    @Column(length = 100, nullable = false)
    private String nombres;

    @Column(length = 100, nullable = false)
    private String apellidos;

    @Column(length = 15)
    private String celular;
    
    @Column(nullable = false)
    private String direccion;

    @Column(name = "id_canton", nullable = false)
    private Integer idCanton;

    @Column(name = "contrato_pdf_path")
    private String contratoPdfPath;

    @Column(name = "croquis_pdf_path")
    private String croquisPdfPath;

    @Column(name = "estado_servicio", length = 20, nullable = false)
    private String estadoServicio;

    @Column(length = 150, unique = true)
    private String correo;

    @Column(name = "fecha_creacion", updatable = false)
    private LocalDateTime fechaCreacion;

    @Column(name = "fecha_actualizacion")
    private LocalDateTime fechaActualizacion;

    @Column(name = "id_empresa", nullable = false)
    private Integer idEmpresa;

    @Column(name = "profile_picture_url")
    private String profilePictureUrl;

    @OneToMany(mappedBy = "cliente", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private java.util.List<DocumentoCliente> documentos;


}
