package com.apweb.backend.repository;

import com.apweb.backend.model.CanalNotificacion;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface CanalNotificacionRepository extends JpaRepository<CanalNotificacion, Integer> {
}
