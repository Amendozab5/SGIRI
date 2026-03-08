package com.apweb.backend.repository;

import com.apweb.backend.model.AuditoriaLogin;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

/**
 * Repositorio JPA para {@code auditoria.auditoria_login}.
 */
@Repository
public interface AuditoriaLoginRepository extends JpaRepository<AuditoriaLogin, Integer> {
}
