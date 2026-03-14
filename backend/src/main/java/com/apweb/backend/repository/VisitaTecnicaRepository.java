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
                        "WHERE v.fechaVisita BETWEEN :start AND :end " +
                        "AND u.id = :tecnicoId")
        List<VisitaTecnica> findByFechaVisitaBetweenAndTecnico_Id(@Param("start") LocalDate start,
                        @Param("end") LocalDate end, @Param("tecnicoId") Integer tecnicoId);

        List<VisitaTecnica> findByFechaVisitaBetween(@Param("start") LocalDate start, @Param("end") LocalDate end);

        List<VisitaTecnica> findByTecnico_Id(Integer tecnicoId);

        List<VisitaTecnica> findByEmpresa_Id(Integer empresaId);

        @Query("SELECT v FROM VisitaTecnica v " +
                        "JOIN FETCH v.ticket t " +
                        "JOIN FETCH v.tecnico u " +
                        "LEFT JOIN FETCH u.persona p " +
                        "JOIN FETCH v.estado e " +
                        "WHERE t.usuarioCreador.id = :userId " +
                        "ORDER BY v.fechaVisita DESC, v.horaInicio DESC")
        List<VisitaTecnica> findByTicket_UsuarioCreador_IdWithAssociations(@Param("userId") Integer userId);

        List<VisitaTecnica> findByTicket_IdTicketOrderByFechaVisitaDesc(Integer idTicket);

        @Query("SELECT v FROM VisitaTecnica v " +
                        "JOIN FETCH v.ticket t " +
                        "LEFT JOIN FETCH t.estadoItem tei " +
                        "LEFT JOIN FETCH t.cliente c " +
                        "LEFT JOIN FETCH c.persona cp " +
                        "JOIN FETCH t.sucursal s " +
                        "LEFT JOIN FETCH s.empresa semp " +
                        "JOIN FETCH v.tecnico u " +
                        "LEFT JOIN FETCH u.persona p " +
                        "JOIN FETCH v.estado e " +
                        "WHERE u.id = :tecnicoId " +
                        "ORDER BY v.fechaVisita DESC, v.horaInicio DESC")
        List<VisitaTecnica> findByTecnico_IdWithAssociations(@Param("tecnicoId") Integer tecnicoId);
}
