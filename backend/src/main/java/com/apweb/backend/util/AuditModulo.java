package com.apweb.backend.util;

/**
 * Constantes de módulos auditables del sistema SGIRI.
 * <p>
 * Uso: pasar como argumento {@code modulo} en {@code AuditService.registrarEvento()}.
 * No se normaliza en BD (sin tabla catálogo) — controlado aquí como única fuente de verdad.
 * </p>
 *
 * <pre>
 * auditService.registrarEvento(AuditModulo.TICKETS, ...);
 * </pre>
 */
public final class AuditModulo {

    /** Módulo de autenticación: login, logout, cambio de contraseña, registro */
    public static final String AUTH = "AUTH";

    /** Gestión de tickets de soporte (creación, asignación, cambio de estado, cierre) */
    public static final String TICKETS = "TICKETS";

    /** Administración de usuarios del sistema */
    public static final String USUARIOS = "USUARIOS";

    /** Gestión de empleados (alta laboral) */
    public static final String EMPLEADOS = "EMPLEADOS";

    /** Documentos laborales de empleados y documentos relacionados */
    public static final String DOCUMENTOS = "DOCUMENTOS";

    /** Visitas técnicas programadas */
    public static final String VISITAS = "VISITAS";

    /** Perfil propio del usuario autenticado */
    public static final String PERFIL = "PERFIL";

    /** Operaciones de mantenimiento y respaldo del sistema */
    public static final String SISTEMA = "SISTEMA";

    private AuditModulo() {
        // Clase de constantes, no instanciable
    }
}
