package com.apweb.backend.repository;

import com.apweb.backend.model.DocumentoCliente;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface DocumentoClienteRepository extends JpaRepository<DocumentoCliente, Integer> {
}
