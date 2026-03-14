package com.apweb.backend.repository;

import com.apweb.backend.model.HistorialGeneracion;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface HistorialGeneracionRepository extends JpaRepository<HistorialGeneracion, Integer> {
}
