package com.apweb.backend.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Diagnóstico completo de las precondiciones para habilitar acceso al sistema
 * a un empleado. El frontend usa esto para decidir qué pantalla o botón mostrar.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class EmpleadoAccessStatusDTO {

    /** La cédula ingresada existe en usuarios.persona */
    private boolean personaExiste;

    /** La persona tiene un registro laboral en empleados.empleado */
    private boolean empleadoExiste;

    /** El empleado tiene al menos un documento con estado ACTIVO */
    private boolean tieneDocumentoActivo;

    /** Ya existe un usuarios.usuario vinculado a este empleado */
    private boolean yaTieneUsuario;

    /**
     * Resumen: puede activarse el acceso.
     * = empleadoExiste && tieneDocumentoActivo && !yaTieneUsuario
     */
    private boolean puedeActivar;

    /**
     * Si ya tiene usuario, su username en el sistema (para mostrar en UI).
     * Null si aún no tiene acceso.
     */
    private String usernameExistente;

    // Mensajes de razón para el bloqueo, útiles en la UI
    private String razonBloqueo;
}
