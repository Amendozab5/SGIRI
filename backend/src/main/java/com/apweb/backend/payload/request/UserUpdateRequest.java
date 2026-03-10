package com.apweb.backend.payload.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class UserUpdateRequest {
    @NotBlank
    @Size(min = 3, max = 50)
    private String username;

    @NotBlank
    @Size(min = 3, max = 100)
    private String nombre;

    @NotBlank
    @Size(min = 3, max = 100)
    private String apellido;

    @NotBlank
    @Size(max = 100)
    private String email;

    @NotBlank
    private String role; // Role code (e.g., "ROLE_ADMIN")

    @NotBlank
    private String estado; // User status (e.g., "ACTIVO", "INACTIVO")
}
