package com.apweb.backend.repository;

import com.apweb.backend.model.AuditTimelineView;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.stereotype.Repository;

/**
 * Repositorio para la vista unificada de auditoría.
 */
@Repository
public interface AuditTimelineRepository extends JpaRepository<AuditTimelineView, String>, JpaSpecificationExecutor<AuditTimelineView> {
}
