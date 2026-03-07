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
public class EmpleadoDTO {

    private Integer idEmpleado;

    // Datos de identidad (de usuarios.persona)
    private String cedula;
    private String nombre;
    private String apellido;
    private String correo;
    private String celular;
    private LocalDate fechaNacimiento;

    // Datos laborales (de empleados.empleado)
    private LocalDate fechaIngreso;

    private Integer idArea;
    private String nombreArea;

    private Integer idCargo;
    private String nombreCargo;

    private Integer idTipoContrato;
    private String nombreTipoContrato;

    private Integer idSucursal;
    private String nombreSucursal;

    // Indicadores de estado
    private boolean tieneDocumentoActivo;
    private boolean tieneUsuarioActivo;
    private String usernameSistema; // null si aún no tiene usuario
}
