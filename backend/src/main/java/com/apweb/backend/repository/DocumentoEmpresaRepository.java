package com.apweb.backend.repository;

import com.apweb.backend.model.DocumentoEmpresa;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface DocumentoEmpresaRepository extends JpaRepository<DocumentoEmpresa, Integer> {
}
