package com.apweb.backend.repository;

import com.apweb.backend.model.Empleado;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface EmpleadoRepository extends JpaRepository<Empleado, Integer> {
    Optional<Empleado> findByCorreoCorporativo(String correo);
    Boolean existsByCorreoCorporativo(String correo);
    Boolean existsByCorreoPersonal(String correo);
}
