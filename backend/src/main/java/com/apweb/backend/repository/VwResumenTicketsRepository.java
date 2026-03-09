package com.apweb.backend.repository;

import com.apweb.backend.model.VwResumenTickets;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import java.util.List;

public interface VwResumenTicketsRepository
        extends JpaRepository<VwResumenTickets, Integer>, JpaSpecificationExecutor<VwResumenTickets> {
    List<VwResumenTickets> findByIdCliente(Integer idCliente);

    List<VwResumenTickets> findByIdUsuarioAsignado(Integer idUsuarioAsignado);
}
