package com.apweb.backend.repository;

import com.apweb.backend.model.UsuarioEmpleado;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface UsuarioEmpleadoRepository extends JpaRepository<UsuarioEmpleado, Integer> {
}
