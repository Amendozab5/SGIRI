package com.apweb.backend.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDate;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class TechnicianDTO {
    private Integer userId;
    private Integer empleadoId;
    private String username;
    private String nombre;
    private String apellido;
    private String cedula;
    private String correo;
    private String celular;
    private String cargo;
    private String area;
    private String tipoContrato;
    private LocalDate fechaIngreso;
    private String foto; // Optional, can be null

    // New Fields for Assign Panel
    private String estado;
    private Long ticketsAsignados;
    private Long ticketsResueltosHoy;
    private Double porcentajeResolucion;
    private String nivelRendimiento;
    private Long ticketsActivos;
    private String especialidad;
    private String historialResumido;
}
