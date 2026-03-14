package com.apweb.backend.repository;

import com.apweb.backend.model.Asignacion;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface AsignacionRepository extends JpaRepository<Asignacion, Integer> {
    @org.springframework.data.jpa.repository.Query("SELECT DISTINCT a FROM Asignacion a " +
            "JOIN FETCH a.ticket t " +
            "LEFT JOIN FETCH t.usuarioAsignado ua " +
            "LEFT JOIN FETCH ua.persona uap " +
            "LEFT JOIN FETCH uap.canton " +
            "LEFT JOIN FETCH t.usuarioCreador uc " +
            "LEFT JOIN FETCH uc.persona ucp " +
            "LEFT JOIN FETCH ucp.canton " +
            "LEFT JOIN FETCH t.estadoItem " +
            "LEFT JOIN FETCH t.categoriaItem " +
            "LEFT JOIN FETCH t.prioridadItem " +
            "LEFT JOIN FETCH t.servicio " +
            "LEFT JOIN FETCH t.sla sla " +
            "LEFT JOIN FETCH sla.aplicaPrioridad " +
            "LEFT JOIN FETCH t.sucursal " +
            "LEFT JOIN FETCH t.cliente c " +
            "LEFT JOIN FETCH c.persona cp " +
            "LEFT JOIN FETCH cp.canton " +
            "WHERE a.usuario = :user AND a.activo = true")
    java.util.List<Asignacion> findByUsuarioAndActivoTrueWithAssociations(@org.springframework.data.repository.query.Param("user") com.apweb.backend.model.User user);

    java.util.List<Asignacion> findByUsuarioAndActivoTrue(com.apweb.backend.model.User user);

    java.util.List<Asignacion> findByTicket(com.apweb.backend.model.Ticket ticket);
}
