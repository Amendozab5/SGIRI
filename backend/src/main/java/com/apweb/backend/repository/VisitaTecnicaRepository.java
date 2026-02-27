package com.apweb.backend.repository;

import com.apweb.backend.model.VisitaTecnica;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDate;
import java.util.List;

@Repository
public interface VisitaTecnicaRepository extends JpaRepository<VisitaTecnica, Integer> {
    @Query("SELECT v FROM VisitaTecnica v " +
            "JOIN FETCH v.ticket t " +
            "JOIN FETCH t.estadoItem ei " +
            "JOIN FETCH t.cliente c " +
            "JOIN FETCH t.sucursal s " +
            "JOIN FETCH v.tecnico u " +
            "JOIN FETCH v.estado e " +
            "JOIN FETCH v.empresa emp " +
            "WHERE v.fechaVisita BETWEEN :start AND :end")
    List<VisitaTecnica> findByFechaVisitaBetween(@Param("start") LocalDate start, @Param("end") LocalDate end);

    List<VisitaTecnica> findByTecnico_Id(Integer tecnicoId);

    List<VisitaTecnica> findByEmpresa_Id(Integer empresaId);
}
