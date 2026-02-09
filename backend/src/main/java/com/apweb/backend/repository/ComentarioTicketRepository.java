package com.apweb.backend.repository;

import com.apweb.backend.model.ComentarioTicket;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface ComentarioTicketRepository extends JpaRepository<ComentarioTicket, Integer> {
}
