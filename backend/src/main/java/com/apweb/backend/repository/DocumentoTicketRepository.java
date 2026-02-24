package com.apweb.backend.repository;

import com.apweb.backend.model.DocumentoTicket;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface DocumentoTicketRepository extends JpaRepository<DocumentoTicket, Integer> {
}
