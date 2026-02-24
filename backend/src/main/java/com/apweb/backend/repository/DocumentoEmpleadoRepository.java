package com.apweb.backend.repository;

import com.apweb.backend.model.DocumentoEmpleado;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface DocumentoEmpleadoRepository extends JpaRepository<DocumentoEmpleado, Integer> {
    Optional<DocumentoEmpleado> findByEmpleado_IdEmpleadoAndTipoDocumento_Codigo(Integer idEmpleado, String codigo);
}
