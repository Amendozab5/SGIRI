package com.apweb.backend.repository;

import com.apweb.backend.model.Ticket;
import com.apweb.backend.model.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface TicketRepository extends JpaRepository<Ticket, Integer> {
    @org.springframework.data.jpa.repository.Query("SELECT t FROM Ticket t LEFT JOIN FETCH t.usuarioAsignado LEFT JOIN FETCH t.estadoItem LEFT JOIN FETCH t.categoriaItem LEFT JOIN FETCH t.sucursal")
    List<Ticket> findAllWithAssociations();

    List<Ticket> findByUsuarioCreador(User user);

    List<Ticket> findByUsuarioAsignado(User user);
}
