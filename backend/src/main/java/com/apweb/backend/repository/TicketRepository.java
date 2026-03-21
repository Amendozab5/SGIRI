package com.apweb.backend.repository;

import com.apweb.backend.model.Ticket;
import com.apweb.backend.model.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface TicketRepository extends JpaRepository<Ticket, Integer> {
        @org.springframework.data.jpa.repository.Query("SELECT t FROM Ticket t " +
                        "LEFT JOIN FETCH t.usuarioAsignado ua " +
                        "LEFT JOIN FETCH ua.persona " +
                        "LEFT JOIN FETCH t.estadoItem " +
                        "LEFT JOIN FETCH t.categoriaItem " +
                        "LEFT JOIN FETCH t.sucursal")
        List<Ticket> findAllWithAssociations();

        @Query("SELECT t FROM Ticket t WHERE t.cliente.persona.user = :user")
        List<Ticket> findByUsuarioCreador(@Param("user") User user);

        @Query("SELECT t FROM Ticket t WHERE t.cliente.persona.user = :user")
        org.springframework.data.domain.Page<Ticket> findByUsuarioCreador(@Param("user") User user,
                        org.springframework.data.domain.Pageable pageable);

        @Query("SELECT t FROM Ticket t " +
                        "LEFT JOIN FETCH t.estadoItem " +
                        "LEFT JOIN FETCH t.categoriaItem " +
                        "LEFT JOIN FETCH t.sucursal " +
                        "WHERE t.cliente.persona.user = :user " +
                        "AND (:searchTerm IS NULL OR :searchTerm = '' OR " +
                        "     LOWER(t.asunto) LIKE LOWER(CONCAT('%', :searchTerm, '%')) OR " +
                        "     CAST(t.idTicket AS String) LIKE CONCAT('%', :searchTerm, '%')) " +
                        "AND (:statusId IS NULL OR t.estadoItem.id = :statusId) " +
                        "AND (:categoryId IS NULL OR t.categoriaItem.id = :categoryId)")
        org.springframework.data.domain.Page<Ticket> findByUsuarioCreadorWithFilters(
                        @Param("user") User user,
                        @Param("searchTerm") String searchTerm,
                        @Param("statusId") Integer statusId,
                        @Param("categoryId") Integer categoryId,
                        org.springframework.data.domain.Pageable pageable);

        @Query("SELECT DISTINCT t FROM Ticket t " +
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
                        "WHERE t.usuarioAsignado = :user")
        List<Ticket> findByUsuarioAsignadoWithAssociations(@Param("user") User user);

        List<Ticket> findByUsuarioAsignado(User user);

        @Query("SELECT AVG(t.calificacionSatisfaccion) FROM Ticket t WHERE t.usuarioAsignado = :tecnico AND t.calificacionSatisfaccion IS NOT NULL")
        Double findAvgRatingByTecnico(@Param("tecnico") User tecnico);

        @Query("SELECT COUNT(t) FROM Ticket t WHERE t.usuarioAsignado = :tecnico AND t.calificacionSatisfaccion IS NOT NULL")
        Long countRatedTicketsByTecnico(@Param("tecnico") User tecnico);

        @Query("SELECT COUNT(t) FROM Ticket t WHERE t.usuarioAsignado = :tecnico")
        Long countTicketsByTecnico(@Param("tecnico") User tecnico);

        @Query("SELECT t FROM Ticket t " +
                        "JOIN FETCH t.estadoItem ei " +
                        "LEFT JOIN FETCH t.cliente c " +
                        "LEFT JOIN FETCH c.persona cp " +
                        "LEFT JOIN FETCH t.sucursal s " +
                        "WHERE ei.codigo = 'REQUIERE_VISITA' " +
                        "AND NOT EXISTS (SELECT v FROM VisitaTecnica v WHERE v.ticket = t AND v.estado.codigo != 'CANCELADA')")
        List<Ticket> findTicketsPendingVisit();
}
