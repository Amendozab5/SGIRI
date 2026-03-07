package com.apweb.backend.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Data;

import java.time.LocalDate;

@Data
public class EmpleadoCreateRequest {

    // ─── Identidad (usuarios.persona) ─────────────────────────────────────────
    /**
     * Cédula de identidad. Si ya existe en usuarios.persona se reutiliza esa persona.
     * Si no existe se crea una nueva persona con los datos a continuación.
     */
    @NotBlank
    @Size(min = 10, max = 10)
    private String cedula;

    private String nombre;      // Requerido solo si la persona no existe aún
    private String apellido;    // Requerido solo si la persona no existe aún
    private String correo;
    private String celular;
    private LocalDate fechaNacimiento;

    // ─── Datos laborales (empleados.empleado) ──────────────────────────────────
    @NotNull
    private LocalDate fechaIngreso;

    @NotNull
    private Integer idCargo;

    @NotNull
    private Integer idArea;

    @NotNull
    private Integer idTipoContrato;

    private Integer idSucursal;  // Opcional — nullable en BD
}
