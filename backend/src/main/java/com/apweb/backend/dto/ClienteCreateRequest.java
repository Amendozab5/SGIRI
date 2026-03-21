package com.apweb.backend.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import lombok.Data;
import java.time.LocalDate;

@Data
public class ClienteCreateRequest {
    @NotBlank
    @Pattern(regexp = "^[0-9]{10,13}$")
    private String cedula;

    @NotBlank
    private String nombre;

    @NotBlank
    private String apellido;

    @Email
    private String correo;

    private String celular;

    private LocalDate fechaNacimiento;

    @NotNull
    private Integer idSucursal;

    private LocalDate fechaInicioContrato;
    private LocalDate fechaFinContrato;
}
