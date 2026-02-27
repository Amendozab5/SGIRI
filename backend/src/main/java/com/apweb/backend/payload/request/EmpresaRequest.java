package com.apweb.backend.payload.request;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class EmpresaRequest {
    @NotBlank
    private String nombreComercial;
    @NotBlank
    private String razonSocial;
    @NotBlank
    private String ruc;
    private String tipoEmpresa; // PUBLIC/PRIVATE
    private String correoContacto;
    private String telefonoContacto;
    private String direccionMatriz;
    private Integer idEstado;
}
