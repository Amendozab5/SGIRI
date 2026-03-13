package com.apweb.backend.repository;

import com.apweb.backend.model.Asignacion;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface AsignacionRepository extends JpaRepository<Asignacion, Integer> {
    java.util.List<Asignacion> findByUsuarioAndActivoTrue(com.apweb.backend.model.User user);

    java.util.List<Asignacion> findByTicket(com.apweb.backend.model.Ticket ticket);
}
