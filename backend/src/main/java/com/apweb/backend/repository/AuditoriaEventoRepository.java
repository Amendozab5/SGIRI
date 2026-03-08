package com.apweb.backend.repository;

import com.apweb.backend.model.AuditoriaEvento;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

/**
 * Repositorio JPA para {@code auditoria.auditoria_evento}.
 * Solo se necesita {@code save()} para esta fase. Consultas de auditoría
 * se añadirán en fases posteriores según necesidades de reporte.
 */
@Repository
public interface AuditoriaEventoRepository extends JpaRepository<AuditoriaEvento, Integer> {
}
