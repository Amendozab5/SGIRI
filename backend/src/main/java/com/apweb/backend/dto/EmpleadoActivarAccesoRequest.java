package com.apweb.backend.dto;

import jakarta.validation.constraints.NotBlank;
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
     * Valores permitidos: TECNICO, ADMIN_TECNICOS, ADMIN_MASTER, ADMIN_CONTRATOS.
     */
    @NotBlank(message = "El campo 'rol' es obligatorio.")
    private String rol;

    /**
     * ID de la empresa. Ya no es obligatorio para empleados internos.
     * Si no se envía, se registrará como NULL en usuarios.usuario.
     */
    private Integer idEmpresa;

    /**
     * Año de nacimiento del empleado. 
     * Opcional. Usado históricamente por fn_generar_credenciales.
     */
    private Integer anioNacimiento;
}
