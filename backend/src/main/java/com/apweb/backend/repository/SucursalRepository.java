package com.apweb.backend.repository;

import com.apweb.backend.model.Sucursal;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface SucursalRepository extends JpaRepository<Sucursal, Integer> {
    List<Sucursal> findByEmpresaId(Integer idEmpresa);
}
