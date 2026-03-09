package com.apweb.backend.repository;

import com.apweb.backend.model.InventarioUsadoTicket;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface InventarioUsadoTicketRepository extends JpaRepository<InventarioUsadoTicket, Integer> {
    List<InventarioUsadoTicket> findByTicket_IdTicket(Integer idTicket);
}
