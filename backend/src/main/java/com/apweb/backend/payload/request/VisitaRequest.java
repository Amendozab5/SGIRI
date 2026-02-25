package com.apweb.backend.payload.request;

import lombok.Data;
import java.time.LocalDate;
import java.time.LocalTime;

@Data
public class VisitaRequest {
    private Integer idTicket;
    private Integer idTecnico;
    private Integer idEmpresa;
    private LocalDate fechaVisita;
    private LocalTime horaInicio;
    private LocalTime horaFin;
    private String codigoEstado; // PROGRAMADA, CONFIRMADA, etc.
    private String reporteVisita;
}
