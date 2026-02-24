package com.apweb.backend.payload.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class SucursalRequest {
    @NotNull
    private Integer idEmpresa;
    @NotBlank
    private String nombre;
    @NotBlank
    private String direccion;
    private String telefono;
    private Integer idCiudad;
    private Integer idCanton;
}
