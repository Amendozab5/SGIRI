package com.apweb.backend.model;

import com.fasterxml.jackson.annotation.JsonBackReference;
import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;

@Entity
@Table(name = "usuario_cliente", schema = "usuarios")
@Data
@NoArgsConstructor
public class UsuarioCliente {

    @Id
    @Column(name = "id_usuario")
    private Integer id;

    @OneToOne(fetch = FetchType.LAZY)
    @MapsId
    @JoinColumn(name = "id_usuario")
    @JsonBackReference("user-cliente")
    private User user;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id_cliente", nullable = false)
    private Cliente cliente;

    @Column(name = "cedula_cliente", length = 10, nullable = false)
    private String cedulaCliente;

    public UsuarioCliente(User user, Cliente cliente) {
        this.user = user;
        this.cliente = cliente;
        this.id = user.getId();
        this.cedulaCliente = cliente.getCedula();
    }
}
