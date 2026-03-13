package com.apweb.backend.repository;

import com.apweb.backend.model.InformeTrabajoTecnico;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.List;

@Repository
public interface InformeTrabajoTecnicoRepository extends JpaRepository<InformeTrabajoTecnico, Integer> {
    Optional<InformeTrabajoTecnico> findByTicket_IdTicket(Integer idTicket);
    List<InformeTrabajoTecnico> findByTicket_IdTicketOrderByIdInformeDesc(Integer idTicket);

    @org.springframework.data.jpa.repository.Query("SELECT i.implementosUsados FROM InformeTrabajoTecnico i WHERE i.resultado = 'RESUELTO'")
    List<String> findAllResolvedImplementos();

    @org.springframework.data.jpa.repository.Query("SELECT i.problemasEncontrados FROM InformeTrabajoTecnico i WHERE i.resultado = 'RESUELTO'")
    List<String> findAllResolvedProblemas();

    @org.springframework.data.jpa.repository.Query("SELECT i.solucionAplicada FROM InformeTrabajoTecnico i WHERE i.resultado = 'RESUELTO'")
    List<String> findAllResolvedSoluciones();
}
