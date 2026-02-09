package com.apweb.backend.payload.request;

import lombok.Data;

@Data
public class ProfileUpdateRequest {
    private String pasaporte;
    private String sexo;
    private String fechaNacimiento;
    private String nacionalidad;
    private Integer aniosResidencia;
    private String correoPersonal;
    private String libretaMilitar;
    private String extensionTelefonica;
    private String estadoCivil;
}