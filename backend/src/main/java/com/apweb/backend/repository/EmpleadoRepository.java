package com.apweb.backend.repository;

import com.apweb.backend.model.Empleado;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.Optional;

@Repository
public interface EmpleadoRepository extends JpaRepository<Empleado, Integer> {
    Optional<Empleado> findByPersona_Correo(String correo);

    Boolean existsByPersona_Correo(String correo);

    Boolean existsByPersona_Cedula(String cedula);

    Optional<Empleado> findByPersona_Cedula(String cedula);
}
