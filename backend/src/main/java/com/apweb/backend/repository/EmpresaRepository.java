package com.apweb.backend.repository;

import com.apweb.backend.model.Empresa;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface EmpresaRepository extends JpaRepository<Empresa, Integer> {
    java.util.Optional<Empresa> findByNombreComercial(String nombreComercial);
}
