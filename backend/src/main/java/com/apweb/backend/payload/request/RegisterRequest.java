package com.apweb.backend.payload.request;

import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import jakarta.validation.constraints.NotNull; // Added this import
import lombok.Data;

@Data
public class RegisterRequest {
    @NotBlank
    @Size(min = 3, max = 20)
    private String nombres;

    @NotBlank
    @Size(min = 3, max = 50)
    private String apellidos;

    @NotBlank
    @Size(min = 10, max = 10) // Assuming Ecuadorian Cedula has 10 digits
    @Pattern(regexp = "^[0-9]*$", message = "La cédula solo puede contener números.")
    private String cedula;

    @NotBlank
    @Size(min = 10, max = 15) // Assuming common phone number length
    @Pattern(regexp = "^[0-9]*$", message = "El número telefónico solo puede contener números.")
    private String numeroTelefonico;

    @NotBlank
    @Size(max = 50)
    @Email
    private String email;

    @JsonProperty("idCanton")
    @NotNull
    private Integer idCanton;
    
    // Password will be handled separately as per user's request
}
