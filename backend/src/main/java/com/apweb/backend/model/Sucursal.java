package com.apweb.backend.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Entity
@Table(name = "sucursal", schema = "empresa")
@Data
@NoArgsConstructor
@AllArgsConstructor
@com.fasterxml.jackson.annotation.JsonIgnoreProperties({ "hibernateLazyInitializer", "handler" })
public class Sucursal {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_sucursal")
    private Integer id;

    @com.fasterxml.jackson.annotation.JsonIgnore
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id_empresa", nullable = false)
    private Empresa empresa;

    @Column(length = 100, nullable = false)
    private String nombre;

    @Column(nullable = false, columnDefinition = "TEXT")
    private String direccion;

    @Column(name = "id_ciudad")
    private Integer idCiudad;

    @Column(name = "id_canton")
    private Integer idCanton;

    @Column(length = 50)
    private String telefono;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "id_catalogo_item_estado")
    private CatalogoItem estado;
}
