package com.apweb.backend.repository;

import com.apweb.backend.model.SlaTicket;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface SlaTicketRepository extends JpaRepository<SlaTicket, Integer> {
}
