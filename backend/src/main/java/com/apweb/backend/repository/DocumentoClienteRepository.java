package com.apweb.backend.repository;

import com.apweb.backend.model.DocumentoCliente;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface DocumentoClienteRepository extends JpaRepository<DocumentoCliente, Integer> {
    Optional<DocumentoCliente> findByCliente_IdClienteAndTipoDocumento_Codigo(Integer idCliente, String codigo);
}
