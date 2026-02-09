package com.apweb.backend.repository;

import com.apweb.backend.model.Cliente;
import com.apweb.backend.model.UsuarioCliente;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface UsuarioClienteRepository extends JpaRepository<UsuarioCliente, Integer> {
    Optional<UsuarioCliente> findByCliente(Cliente cliente);
}
