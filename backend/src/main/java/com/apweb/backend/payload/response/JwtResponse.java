package com.apweb.backend.payload.response;

import lombok.Data;

import java.util.List;

@Data
public class JwtResponse {
    private String token;
    private String type = "Bearer";
    private Integer id;
    private String username;
    private String email;
    private List<String> roles;
    private boolean primerLogin;
    private Integer idEmpresa;

    public JwtResponse(String accessToken, Integer id, String username, String email, List<String> roles,
            boolean primerLogin, Integer idEmpresa) {
        this.token = accessToken;
        this.id = id;
        this.username = username;
        this.email = email;
        this.roles = roles;
        this.primerLogin = primerLogin;
        this.idEmpresa = idEmpresa;
    }
}
