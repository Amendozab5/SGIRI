package com.apweb.backend.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Entity
@Table(name = "tipo_contrato", schema = "empleados")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class TipoContrato {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_tipo_contrato")
    private Integer id;

    @Column(nullable = false, length = 100, unique = true)
    private String nombre;
}
