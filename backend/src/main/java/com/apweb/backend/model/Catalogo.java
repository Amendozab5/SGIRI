package com.apweb.backend.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Entity
@Table(name = "catalogo", schema = "catalogos")
@Data
@NoArgsConstructor
@AllArgsConstructor
@com.fasterxml.jackson.annotation.JsonIgnoreProperties({ "hibernateLazyInitializer", "handler" })
public class Catalogo {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_catalogo")
    private Integer id;

    @Column(length = 100, nullable = false, unique = true)
    private String nombre;

    @Column(columnDefinition = "TEXT")
    private String descripcion;

    private Boolean activo;

    @com.fasterxml.jackson.annotation.JsonManagedReference
    @OneToMany(mappedBy = "catalogo", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private List<CatalogoItem> items;
}
