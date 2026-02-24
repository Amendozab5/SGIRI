package com.apweb.backend.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Entity
@Table(name = "servicio", schema = "empresa")
@Data
@NoArgsConstructor
@AllArgsConstructor
@com.fasterxml.jackson.annotation.JsonIgnoreProperties({ "hibernateLazyInitializer", "handler" })
public class Servicio {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_servicio")
    private Integer id;

    @Column(length = 100, nullable = false, unique = true)
    private String nombre;

    @Column(columnDefinition = "TEXT")
    private String descripcion;

    private Boolean activo;

    @com.fasterxml.jackson.annotation.JsonIgnore
    @ManyToMany(mappedBy = "servicios")
    private java.util.Set<Empresa> empresas;

}
