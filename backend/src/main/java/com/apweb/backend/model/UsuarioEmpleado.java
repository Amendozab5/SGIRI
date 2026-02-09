package com.apweb.backend.model;

import com.fasterxml.jackson.annotation.JsonBackReference;
import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;

@Entity
@Table(name = "usuario_empleado", schema = "usuarios")
@Data
@NoArgsConstructor
public class UsuarioEmpleado {

    @Id
    @Column(name = "id_usuario")
    private Integer id;

    @OneToOne(fetch = FetchType.LAZY)
    @MapsId
    @JoinColumn(name = "id_usuario")
    @JsonBackReference("user-empleado")
    private User user;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id_empleado", nullable = false)
    private Empleado empleado;

    @Column(name = "cedula_empleado", length = 10, nullable = false)
    private String cedulaEmpleado;

    public UsuarioEmpleado(User user, Empleado empleado) {
        this.user = user;
        this.empleado = empleado;
        this.id = user.getId();
        this.cedulaEmpleado = empleado.getCedula();
    }
}
