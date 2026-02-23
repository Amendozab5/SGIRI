package com.apweb.backend.repository;

import com.apweb.backend.model.Ticket;
import com.apweb.backend.model.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface TicketRepository extends JpaRepository<Ticket, Integer> {
    List<Ticket> findByUsuarioCreador(User user);

    List<Ticket> findByUsuarioAsignado(User user);
}
