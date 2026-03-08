package com.apweb.backend.util;

/**
 * Códigos de acciones de auditoría que corresponden a los ítems del catálogo
 * {@code ACCION_AUDITORIA} (id_catalogo = 8) en PostgreSQL.
 * <p>
 * Cada constante debe existir como {@code codigo} en {@code catalogos.catalogo_item}.
 * Los scripts SQL {@code V4__audit_catalogo_acciones.sql} insertan los ítems faltantes.
 * </p>
 */
public final class AuditAccion {

    // ── Existentes en BD (id_item 30-34) ──────────────────────────────────────
    /** Inserción de un nuevo registro */
    public static final String INSERT = "INSERT";

    /** Actualización de un registro existente */
    public static final String UPDATE = "UPDATE";

    /** Eliminación de un registro */
    public static final String DELETE = "DELETE";

    /** Inicio de sesión exitoso */
    public static final String LOGIN = "LOGIN";

    /** Cambio de estado de una entidad (ticket, visita, documento) */
    public static final String CAMBIO_ESTADO = "CAMBIO_ESTADO";

    /** Cierre de sesión manual */
    public static final String LOGOUT = "LOGOUT";

    // ── Nuevos — insertados por V4__audit_catalogo_acciones.sql ──────────────
    /** Intento de login fallido (credenciales incorrectas, usuario inactivo, etc.) */
    public static final String LOGIN_FALLIDO = "LOGIN_FALLIDO";

    /** Cambio de contraseña por parte del usuario */
    public static final String CAMBIO_PASSWORD = "CAMBIO_PASSWORD";

    /** Auto-registro de un nuevo usuario cliente */
    public static final String REGISTRO_USUARIO = "REGISTRO_USUARIO";

    /** Activación de acceso al sistema para un empleado */
    public static final String ACTIVACION_ACCESO = "ACTIVACION_ACCESO";

    /** Eliminación o revocación de acceso de un usuario */
    public static final String REVOCACION_ACCESO = "REVOCACION_ACCESO";

    /** Carga de un documento (foto de perfil, documento laboral, etc.) */
    public static final String UPLOAD_DOCUMENTO = "UPLOAD_DOCUMENTO";

    /** Cambio de estado de un documento (PENDIENTE → ACTIVO, RECHAZADO, etc.) */
    public static final String CAMBIO_ESTADO_DOC = "CAMBIO_ESTADO_DOC";

    /** Comentario añadido a un ticket */
    public static final String COMENTARIO = "COMENTARIO";

    /** Calificación de servicio registrada por el cliente */
    public static final String CALIFICACION = "CALIFICACION";

    private AuditAccion() {
        // Clase de constantes, no instanciable
    }
}
