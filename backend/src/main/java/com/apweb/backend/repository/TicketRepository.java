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
    @org.springframework.data.jpa.repository.Query("SELECT t FROM Ticket t LEFT JOIN FETCH t.usuarioAsignado LEFT JOIN FETCH t.estadoItem LEFT JOIN FETCH t.categoriaItem LEFT JOIN FETCH t.sucursal")
    List<Ticket> findAllWithAssociations();

    List<Ticket> findByUsuarioCreador(User user);

    List<Ticket> findByUsuarioAsignado(User user);

    @Query("SELECT AVG(t.calificacionSatisfaccion) FROM Ticket t WHERE t.usuarioAsignado = :tecnico AND t.calificacionSatisfaccion IS NOT NULL")
    Double findAvgRatingByTecnico(@Param("tecnico") User tecnico);

    @Query("SELECT COUNT(t) FROM Ticket t WHERE t.usuarioAsignado = :tecnico AND t.calificacionSatisfaccion IS NOT NULL")
    Long countRatedTicketsByTecnico(@Param("tecnico") User tecnico);

    @Query("SELECT COUNT(t) FROM Ticket t WHERE t.usuarioAsignado = :tecnico")
    Long countTicketsByTecnico(@Param("tecnico") User tecnico);
}
