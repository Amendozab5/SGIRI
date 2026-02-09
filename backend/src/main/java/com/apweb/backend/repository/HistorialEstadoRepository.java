package com.apweb.backend.repository;

import com.apweb.backend.model.HistorialEstado;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface HistorialEstadoRepository extends JpaRepository<HistorialEstado, Integer> {
}
