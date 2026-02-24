package com.apweb.backend.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Entity
@Table(name = "tipo_documento", schema = "clientes")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class TipoDocumento {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_tipo_documento")
    private Integer id;

    @Column(length = 20, nullable = false, unique = true)
    private String codigo;
}
