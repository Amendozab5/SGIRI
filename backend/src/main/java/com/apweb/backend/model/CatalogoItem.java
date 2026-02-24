package com.apweb.backend.model;

import com.fasterxml.jackson.annotation.JsonBackReference;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Entity
@Table(name = "catalogo_item", schema = "catalogos")
@Data
@NoArgsConstructor
@AllArgsConstructor
@com.fasterxml.jackson.annotation.JsonIgnoreProperties({ "hibernateLazyInitializer", "handler" })
public class CatalogoItem {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_item")
    private Integer id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id_catalogo", nullable = false)
    @JsonBackReference
    private Catalogo catalogo;

    @Column(length = 50)
    private String codigo;

    @Column(length = 100, nullable = false)
    private String nombre;

    private Integer orden;

    private Boolean activo;
}
