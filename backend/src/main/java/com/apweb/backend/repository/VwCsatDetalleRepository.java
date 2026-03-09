package com.apweb.backend.repository;

import com.apweb.backend.model.VwCsatDetalle;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface VwCsatDetalleRepository extends JpaRepository<VwCsatDetalle, Integer> {
}
