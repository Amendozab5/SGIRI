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
    private String role; // Role code (e.g., "ROLE_ADMIN")

    @NotBlank
    private String estado; // User status (e.g., "ACTIVO", "INACTIVO")
}
