package com.apweb.backend.repository;

import com.apweb.backend.model.AuditoriaEstadoTicket;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

/**
 * Repositorio JPA para {@code auditoria.auditoria_estado_ticket}.
 */
@Repository
public interface AuditoriaEstadoTicketRepository extends JpaRepository<AuditoriaEstadoTicket, Integer> {
}
