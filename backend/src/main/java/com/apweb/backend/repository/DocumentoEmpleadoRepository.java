package com.apweb.backend.repository;

import com.apweb.backend.model.DocumentoEmpleado;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface DocumentoEmpleadoRepository extends JpaRepository<DocumentoEmpleado, Integer> {
}
