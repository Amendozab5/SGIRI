package com.apweb.backend.payload.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

/**
 * Solicitud de creación de usuario desde el panel de administración.
 *
 * Campos de trazabilidad (cedula, idEmpresa, anioNacimiento) son requeridos
 * cuando el rol es de tipo empleado (TECNICO, ADMIN_*), ya que se usarán
 * para invocar usuarios.fn_crear_usuario_empleado(...) en PostgreSQL,
 * lo cual crea el usuario físico BD y lo asocia al rol BD correspondiente.
 *
 * Para el rol CLIENTE, estos campos son opcionales y se ignoran.
 */
@Data
public class UserCreateRequest {

    @Size(min = 3, max = 50)
    private String username;

    @Size(min = 6, max = 120)
    private String password;

    @NotBlank
    private String role; // Código del rol, ej: "TECNICO", "ADMIN_MASTER"

    // Requerido para roles de empleado — usado por fn_crear_usuario_empleado
    private String cedula;

    // Requerido para roles de empleado — empresa a la que pertenece
    private Integer idEmpresa;
}
