package com.apweb.backend.dto;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

/**
 * Solicitud para habilitar el acceso al sistema a un empleado existente.
 *
 * <p>Este DTO se envía a {@code POST /api/personnel/empleados/{cedula}/activar-acceso}.
 * La cédula viene en el path, no en el body.</p>
 *
 * <p>Las credenciales (username y password) NO se incluyen porque son generadas
 * automáticamente por {@code usuarios.fn_crear_usuario_empleado(...)}, que toma
 * los datos de identidad desde {@code usuarios.persona} y construye un username
 * único y una contraseña temporal basada en la cédula y el año de nacimiento.</p>
 */
@Data
public class EmpleadoActivarAccesoRequest {

    /**
     * Código del rol aplicativo que recibirá el empleado.
     * Valores permitidos: TECNICO, ADMIN_TECNICOS, ADMIN_MASTER, ADMIN_VISUAL.
     */
    @NotBlank(message = "El campo 'rol' es obligatorio.")
    private String rol;

    /**
     * ID de la empresa a la que pertenece el empleado.
     * Se registrará en usuarios.usuario.id_empresa para trazabilidad organizacional.
     */
    @NotNull(message = "El campo 'idEmpresa' es obligatorio.")
    private Integer idEmpresa;

    /**
     * Año de nacimiento del empleado. Usado por fn_generar_credenciales para
     * construir la contraseña temporal: {cedula}*{5 dígitos aleatorios}.
     * Rango válido: 1940–2010.
     */
    @NotNull(message = "El campo 'anioNacimiento' es obligatorio.")
    @Min(value = 1940, message = "Año de nacimiento inválido.")
    @Max(value = 2010, message = "Año de nacimiento inválido.")
    private Integer anioNacimiento;
}
