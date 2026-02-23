package com.apweb.backend.payload.response;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.util.List;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class UserProfileResponse {
    private Integer id;
    private String username;
    private String email;
    private List<String> roles;
    private String nombre;
    private String apellidos;
    private String cedula;
    private String celular;
    private String rutaFoto;
    private Integer idEmpresa;
}
