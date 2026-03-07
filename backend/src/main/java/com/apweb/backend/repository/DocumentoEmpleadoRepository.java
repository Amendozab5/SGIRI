package com.apweb.backend.repository;

import com.apweb.backend.model.DocumentoEmpleado;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface DocumentoEmpleadoRepository extends JpaRepository<DocumentoEmpleado, Integer> {

    Optional<DocumentoEmpleado> findByEmpleado_IdEmpleadoAndTipoDocumento_Codigo(Integer idEmpleado, String codigo);

    /** Todos los documentos de un empleado, para la pestaña de documentos */
    List<DocumentoEmpleado> findByEmpleado_IdEmpleado(Integer idEmpleado);

    /** Verifica si existe al menos un documento con estado ACTIVO para el empleado */
    boolean existsByEmpleado_IdEmpleadoAndEstado_Codigo(Integer idEmpleado, String codigoEstado);

    /** Verifica si existe al menos un documento ACTIVO buscando por cédula (para compatibilidad con la función SQL) */
    boolean existsByCedulaEmpleadoAndEstado_Codigo(String cedulaEmpleado, String codigoEstado);
}
