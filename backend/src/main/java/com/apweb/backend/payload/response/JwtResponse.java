package com.apweb.backend.payload.response;

import lombok.Data;

import java.util.List;

@Data
public class JwtResponse {
    private String token;
    private String type = "Bearer";
    private Integer id; // Changed from Long to Integer
    private String username;
    private String email;
    private List<String> roles;
    private String profilePictureUrl;
    private boolean primerLogin;

    public JwtResponse(String accessToken, Integer id, String username, String email, List<String> roles, String profilePictureUrl, boolean primerLogin) {
        this.token = accessToken;
        this.id = id;
        this.username = username;
        this.email = email;
        this.roles = roles;
        this.profilePictureUrl = profilePictureUrl;
        this.primerLogin = primerLogin;
    }
}

