package com.apweb.backend.service;

import com.apweb.backend.model.AuditoriaEstadoTicket;
import com.apweb.backend.model.AuditoriaEvento;
import com.apweb.backend.model.AuditoriaLogin;
import com.apweb.backend.model.CatalogoItem;
import com.apweb.backend.repository.AuditoriaEstadoTicketRepository;
import com.apweb.backend.repository.AuditoriaEventoRepository;
import com.apweb.backend.repository.AuditoriaLoginRepository;
import com.apweb.backend.repository.CatalogoItemRepository;
import com.apweb.backend.security.jwt.CustomUserDetails;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.servlet.http.HttpServletRequest;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;

import java.util.Map;
import java.util.Optional;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Servicio centralizado de auditoría para SGIRI.
 *
 * <h3>Principios de diseño:</h3>
 * <ul>
 *   <li>Toda escritura usa {@code REQUIRES_NEW}: la transacción de auditoría es
 *       independiente de la transacción de negocio. Un fallo de auditoría NO revierte
 *       la operación principal.</li>
 *   <li>El servicio resuelve internamente IP, User-Agent, endpoint y usuario autenticado
 *       usando {@link RequestContextHolder} — no requiere que los servicios de negocio
 *       le pasen {@link HttpServletRequest} como parámetro.</li>
 *   <li>Si algún dato de contexto no está disponible (contexto fuera de HTTP, scheduler),
 *       se guarda {@code null} sin lanzar excepción.</li>
 *   <li>Los valores anteriores/nuevos se serializan como JSON String usando Jackson.
 *       <strong>NUNCA</strong> se serializan entidades JPA completas — solo
 *       {@link Map}&lt;String, Object&gt; con campos primitivos.</li>
 *   <li>Los IDs de catálogo se cachean en memoria para evitar N+1 queries repetidas
 *       en cada evento auditado.</li>
 * </ul>
 *
 * <h3>Uso básico:</h3>
 * <pre>
 * // Login exitoso
 * auditService.registrarLoginExitoso("amendozab", "emp_0503360398_7", 12);
 *
 * // Login fallido
 * auditService.registrarLoginFallido("amendozab", "Credenciales incorrectas");
 *
 * // Evento genérico (INSERT)
 * Map&lt;String, Object&gt; nuevo = Map.of("asunto", ticket.getAsunto(), "idCliente", cliente.getId());
 * auditService.registrarEvento(AuditModulo.TICKETS, "soporte", "ticket",
 *     ticket.getIdTicket(), AuditAccion.INSERT, "Ticket creado por cliente", null, nuevo, idUsuario);
 *
 * // Cambio de estado de ticket (escribe en auditoria_estado_ticket)
 * auditService.registrarCambioEstadoTicket(idTicket, idEstadoAnterior, idEstadoNuevo,
 *     usuarioBd, idUsuario);
 * </pre>
 */
@Service
public class AuditService {

    private static final Logger log = LoggerFactory.getLogger(AuditService.class);

    private static final String UNKNOWN_USER_BD  = "sgiri_app";
    private static final String UNKNOWN_ROL_BD   = "sgiri_app";
    private static final String CATALOGO_ACCIONES = "ACCION_AUDITORIA";

    private final AuditoriaEventoRepository      eventoRepo;
    private final AuditoriaLoginRepository       loginRepo;
    private final AuditoriaEstadoTicketRepository estadoTicketRepo;
    private final CatalogoItemRepository          catalogoItemRepo;
    private final ObjectMapper                    objectMapper;

    /**
     * Caché en memoria de IDs de catálogo por código.
     * Evita una query a BD en cada evento auditado.
     * Se llena bajo demanda (lazy) y nunca se invalida (catálogos son estables).
     */
    private final Map<String, Integer> catalogoCache = new ConcurrentHashMap<>();

    public AuditService(AuditoriaEventoRepository eventoRepo,
                        AuditoriaLoginRepository loginRepo,
                        AuditoriaEstadoTicketRepository estadoTicketRepo,
                        CatalogoItemRepository catalogoItemRepo,
                        ObjectMapper objectMapper) {
        this.eventoRepo       = eventoRepo;
        this.loginRepo        = loginRepo;
        this.estadoTicketRepo = estadoTicketRepo;
        this.catalogoItemRepo = catalogoItemRepo;
        this.objectMapper     = objectMapper;
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // MÉTODOS PÚBLICOS DE AUDITORÍA
    // ═══════════════════════════════════════════════════════════════════════════

    /**
     * Registra un login exitoso en {@code auditoria.auditoria_login}.
     *
     * @param usernameApp Username de la aplicación (ej. "amendozab")
     * @param usuarioBd   Rol físico PostgreSQL (ej. "emp_0503360398_7") o null para clientes
     * @param idUsuario   ID del usuario en {@code usuarios.usuario}
     */
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void registrarLoginExitoso(String usernameApp, String usuarioBd, Integer idUsuario) {
        try {
            AuditoriaLogin registro = AuditoriaLogin.builder()
                    .usuarioApp(usernameApp)
                    .usuarioBd(usuarioBd)
                    .idUsuario(idUsuario)
                    .exito(Boolean.TRUE)
                    .motivoFallo(null)
                    .ipOrigen(resolveIp())
                    .userAgent(resolveUserAgent())
                    .idItemEvento(resolveAccionId("LOGIN"))
                    .build();

            loginRepo.save(registro);
            log.debug("[AUDIT] Login exitoso registrado — user: {}, ip: {}", usernameApp, registro.getIpOrigen());

        } catch (Exception e) {
            log.error("[AUDIT] Error al registrar login exitoso para '{}': {}", usernameApp, e.getMessage());
        }
    }

    /**
     * Registra un intento de login fallido en {@code auditoria.auditoria_login}.
     *
     * @param usernameIntentado Username que se intentó (puede no existir en BD)
     * @param motivoFallo       Descripción del motivo: "Credenciales incorrectas", "Cuenta inactiva", etc.
     */
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void registrarLoginFallido(String usernameIntentado, String motivoFallo) {
        try {
            AuditoriaLogin registro = AuditoriaLogin.builder()
                    .usuarioApp(usernameIntentado)
                    .usuarioBd(null)
                    .idUsuario(null)
                    .exito(Boolean.FALSE)
                    .motivoFallo(motivoFallo)
                    .ipOrigen(resolveIp())
                    .userAgent(resolveUserAgent())
                    .idItemEvento(resolveAccionId("LOGIN_FALLIDO"))
                    .build();

            loginRepo.save(registro);
            log.debug("[AUDIT] Login FALLIDO registrado — user: {}, motivo: {}, ip: {}",
                    usernameIntentado, motivoFallo, registro.getIpOrigen());

        } catch (Exception e) {
            log.error("[AUDIT] Error al registrar login fallido para '{}': {}", usernameIntentado, e.getMessage());
        }
    }

    /**
     * Registra un evento genérico en {@code auditoria.auditoria_evento}.
     *
     * <p>Usar con {@link com.apweb.backend.util.AuditModulo} y
     * {@link com.apweb.backend.util.AuditAccion} para evitar strings hardcodeados.</p>
     *
     * <p><strong>Importante:</strong> {@code valoresAnteriores} y {@code valoresNuevos}
     * deben ser {@link Map}&lt;String, Object&gt; con valores primitivos o Strings.
     * NUNCA pasar entidades JPA — causaría serialización infinita.</p>
     *
     * @param modulo            Área funcional (usar constantes de {@link com.apweb.backend.util.AuditModulo})
     * @param esquema           Schema PostgreSQL afectado (ej. "soporte", "usuarios")
     * @param tabla             Nombre de la tabla afectada (ej. "ticket", "usuario")
     * @param idRegistro        PK del registro afectado
     * @param codigoAccion      Código del catálogo ACCION_AUDITORIA (usar {@link com.apweb.backend.util.AuditAccion})
     * @param descripcion       Texto libre corto descriptivo del evento
     * @param valoresAnteriores Map con campos antes del cambio (null en INSERT)
     * @param valoresNuevos     Map con campos después del cambio (null en DELETE)
     * @param idUsuario         ID del usuario que ejecutó la acción
     */
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void registrarEvento(String modulo,
                                String esquema,
                                String tabla,
                                Integer idRegistro,
                                String codigoAccion,
                                String descripcion,
                                Map<String, Object> valoresAnteriores,
                                Map<String, Object> valoresNuevos,
                                Integer idUsuarioOverride) {
        
        Integer finalActorId = (idUsuarioOverride != null) ? idUsuarioOverride : resolveCurrentUserId();
        
        registrarEventoInterno(modulo, esquema, tabla, idRegistro, codigoAccion,
                descripcion, valoresAnteriores, valoresNuevos, finalActorId, true, null);
    }

    /**
     * Variante sobrecargada que resuelve automáticamente el idUsuario del contexto
     * de Spring Security. Ideal para flujos que ya están protegidos por autenticación.
     */
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void registrarEventoContextual(String modulo,
                                          String esquema,
                                          String tabla,
                                          Integer idRegistro,
                                          String codigoAccion,
                                          String descripcion,
                                          Map<String, Object> valoresAnteriores,
                                          Map<String, Object> valoresNuevos) {
        
        registrarEvento(modulo, esquema, tabla, idRegistro, codigoAccion, 
                descripcion, valoresAnteriores, valoresNuevos, null);
    }

    /**
     * Registra un evento genérico con indicación explícita de si fue exitoso.
     * Usar cuando la operación de negocio falló pero se quiere dejar registro del intento.
     *
     * @param exito      true si la operación fue exitosa; false si falló
     * @param observacion Nota adicional (mensaje de error, motivo de fallo, etc.)
     */
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void registrarEventoConResultado(String modulo,
                                            String esquema,
                                            String tabla,
                                            Integer idRegistro,
                                            String codigoAccion,
                                            String descripcion,
                                            Map<String, Object> valoresAnteriores,
                                            Map<String, Object> valoresNuevos,
                                            Integer idUsuario,
                                            boolean exito,
                                            String observacion) {
        registrarEventoInterno(modulo, esquema, tabla, idRegistro, codigoAccion,
                descripcion, valoresAnteriores, valoresNuevos, idUsuario, exito, observacion);
    }

    /**
     * Registra un cambio de estado de ticket en la tabla especializada
     * {@code auditoria.auditoria_estado_ticket}.
     *
     * <p>Este método complementa (no reemplaza) a {@code soporte.historial_estado}.
     * Ambas tablas coexisten con propósitos distintos.</p>
     *
     * @param idTicket         ID del ticket afectado
     * @param idEstadoAnterior id_item del estado anterior (null en creación inicial)
     * @param idEstadoNuevo    id_item del nuevo estado activo
     * @param usuarioBd        Rol físico PostgreSQL del ejecutor
     * @param idUsuario        ID del usuario de la aplicación
     */
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void registrarCambioEstadoTicket(Integer idTicket,
                                            Integer idEstadoAnterior,
                                            Integer idEstadoNuevo,
                                            String usuarioBd,
                                            Integer idUsuario) {
        try {
            AuditoriaEstadoTicket registro = AuditoriaEstadoTicket.builder()
                    .idTicket(idTicket)
                    .idEstadoAnterior(idEstadoAnterior)
                    .idEstadoNuevo(idEstadoNuevo)
                    .usuarioBd(usuarioBd != null ? usuarioBd : UNKNOWN_USER_BD)
                    .idUsuario(idUsuario)
                    .idItemEvento(resolveAccionId("CAMBIO_ESTADO"))
                    .build();

            estadoTicketRepo.save(registro);
            log.debug("[AUDIT] Cambio estado ticket #{}: {} → {}", idTicket, idEstadoAnterior, idEstadoNuevo);

        } catch (Exception e) {
            log.error("[AUDIT] Error al registrar cambio estado ticket #{}: {}", idTicket, e.getMessage());
        }
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // MÉTODOS DE RESOLUCIÓN DE CONTEXTO (públicos — uso desde AuthController)
    // ═══════════════════════════════════════════════════════════════════════════

    /**
     * Obtiene el ID del usuario autenticado actualmente desde el SecurityContext.
     * Retorna null si no hay sesión activa (ej. login fallido, contexto sin auth).
     */
    public Integer resolveCurrentUserId() {
        try {
            Authentication auth = SecurityContextHolder.getContext().getAuthentication();
            if (auth != null && auth.getPrincipal() instanceof CustomUserDetails userDetails) {
                return userDetails.getIdUsuario();
            }
        } catch (Exception ignored) {}
        return null;
    }

    /**
     * Obtiene el rol físico PostgreSQL (dbUsername) del usuario autenticado.
     * Retorna "sgiri_app" como fallback seguro si no está disponible.
     */
    public String resolveDbUsername() {
        try {
            Authentication auth = SecurityContextHolder.getContext().getAuthentication();
            if (auth != null && auth.getPrincipal() instanceof CustomUserDetails userDetails) {
                String dbUser = userDetails.getDbUsername();
                String appUser = userDetails.getUsername();
                
                // Si el dbUser es nulo o vacío, el usuario no tiene rol físico asociado (ej. Clientes).
                if (dbUser == null || dbUser.isBlank()) {
                    return UNKNOWN_USER_BD;
                }

                // Si el dbUser es igual al appUser, hay una inconsistencia (mezcla semántica).
                // Forzamos fallback al usuario técnico pero avisamos internamente si fuera posible.
                if (dbUser.equalsIgnoreCase(appUser)) {
                    log.debug("Mezcla semántica detectada: dbUser {} igual a appUser {}. Usando fallback.", dbUser, appUser);
                    return UNKNOWN_USER_BD;
                }

                return dbUser;
            }
        } catch (Exception ignored) {}
        return UNKNOWN_USER_BD;
    }

    /**
     * Obtiene el nombre de rol de la aplicación (ej. "ROLE_TECNICO").
     * Retorna "sgiri_app" como fallback.
     */
    public String resolveRolApp() {
        try {
            Authentication auth = SecurityContextHolder.getContext().getAuthentication();
            if (auth != null && auth.getAuthorities() != null && !auth.getAuthorities().isEmpty()) {
                return auth.getAuthorities().iterator().next().getAuthority();
            }
        } catch (Exception ignored) {}
        return UNKNOWN_ROL_BD;
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // IMPLEMENTACIÓN INTERNA
    // ═══════════════════════════════════════════════════════════════════════════

    /**
     * Implementación interna que realiza la escritura en auditoria_evento.
     * Separada para evitar duplicación de lógica try/catch entre los métodos públicos.
     */
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void registrarEventoInterno(String modulo,
                                        String esquema,
                                        String tabla,
                                        Integer idRegistro,
                                        String codigoAccion,
                                        String descripcion,
                                        Map<String, Object> valoresAnteriores,
                                        Map<String, Object> valoresNuevos,
                                        Integer idUsuario,
                                        boolean exito,
                                        String observacion) {
        try {
            String usuarioBd = resolveDbUsername();
            String rolBd     = resolveRolApp();
            String ip        = resolveIp();
            String ua        = resolveUserAgent();
            String endpoint  = resolveEndpoint();
            String metodo    = resolveMetodoHttp();

            String jsonAnterior = toJson(valoresAnteriores);
            String jsonNuevo    = toJson(valoresNuevos);

            Integer idAccion = resolveAccionId(codigoAccion);
            if (idAccion == null) {
                log.error("[AUDIT] ERROR CRÍTICO: Acción '{}' no encontrada en catálogo 'ACCION_AUDITORIA'. El evento se perdiò.", codigoAccion);
                return;
            }

            AuditoriaEvento evento = AuditoriaEvento.builder()
                    .modulo(modulo)
                    .esquemaAfectado(esquema != null ? esquema : "desconocido")
                    .tablaAfectada(tabla != null ? tabla : "desconocida")
                    .idRegistro(idRegistro != null ? idRegistro : 0)
                    .descripcion(descripcion)
                    .valoresAnteriores(jsonAnterior)
                    .valoresNuevos(jsonNuevo)
                    .observacion(observacion)
                    .exito(exito)
                    .usuarioBd(usuarioBd)
                    .rolBd(rolBd)
                    .idUsuario(idUsuario)
                    .ipOrigen(ip)
                    .userAgent(ua)
                    .endpoint(endpoint)
                    .metodoHttp(metodo)
                    .idAccionItem(idAccion)
                    .build();

            eventoRepo.save(evento);
            log.debug("[AUDIT] Evento registrado — modulo: {}, tabla: {}, accion: {}, id: {}",
                    modulo, tabla, codigoAccion, idRegistro);

        } catch (Exception e) {
            // El fallo de auditoría NUNCA debe romper la operación de negocio
            log.error("[AUDIT] ERROR CRÍTICO al registrar evento ({}.{}, accion={}, id={}): {}",
                    esquema, tabla, codigoAccion, idRegistro, e.getMessage(), e);
        }
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // UTILIDADES PRIVADAS: HTTP CONTEXT
    // ═══════════════════════════════════════════════════════════════════════════

    /**
     * Obtiene el {@link HttpServletRequest} actual usando {@link RequestContextHolder}.
     * Retorna null si no hay contexto HTTP activo (schedulers, tests, etc.).
     */
    private HttpServletRequest getCurrentRequest() {
        try {
            return ((ServletRequestAttributes) RequestContextHolder
                    .currentRequestAttributes()).getRequest();
        } catch (IllegalStateException e) {
            return null; // Contexto fuera de HTTP request (scheduler, test, etc.)
        }
    }

    /**
     * Resuelve la IP real del cliente.
     * Considera header {@code X-Forwarded-For} para casos de proxy o load balancer.
     */
    private String resolveIp() {
        HttpServletRequest request = getCurrentRequest();
        if (request == null) return null;
        String forwarded = request.getHeader("X-Forwarded-For");
        if (forwarded != null && !forwarded.isBlank()) {
            return forwarded.split(",")[0].trim();
        }
        return request.getRemoteAddr();
    }

    private String resolveUserAgent() {
        HttpServletRequest request = getCurrentRequest();
        if (request == null) return null;
        return request.getHeader("User-Agent");
    }

    private String resolveEndpoint() {
        HttpServletRequest request = getCurrentRequest();
        if (request == null) return null;
        return request.getRequestURI();
    }

    private String resolveMetodoHttp() {
        HttpServletRequest request = getCurrentRequest();
        if (request == null) return null;
        return request.getMethod();
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // UTILIDADES PRIVADAS: CATÁLOGO y JSON
    // ═══════════════════════════════════════════════════════════════════════════

    /**
     * Resuelve el id_item del catálogo ACCION_AUDITORIA por su código.
     * Usa caché en memoria para evitar queries repetidas.
     *
     * @param codigo Código del ítem (ej. "INSERT", "LOGIN_FALLIDO")
     * @return id_item del ítem, o null si no existe en BD
     */
    private Integer resolveAccionId(String codigo) {
        // computeIfAbsent no almacena null values correctamente en ConcurrentHashMap.
        // Usamos getOrDefault + put manual para manejar el caso de clave no encontrada.
        if (catalogoCache.containsKey(codigo)) {
            return catalogoCache.get(codigo);
        }
        Optional<CatalogoItem> item = catalogoItemRepo.findByCatalogo_NombreAndCodigo(CATALOGO_ACCIONES, codigo);
        if (item.isEmpty()) {
            log.warn("[AUDIT] Código de acción '{}' no encontrado en catálogo '{}'. "
                    + "Ejecute V4__audit_catalogo_acciones.sql si el ítem es nuevo.", codigo, CATALOGO_ACCIONES);
            return null; // No cachear null — permitir reintentar en futuras invocaciones
        }
        Integer id = item.get().getId();
        catalogoCache.put(codigo, id);
        return id;
    }

    /**
     * Serializa un Map a JSON String usando Jackson.
     * Retorna null si el mapa es null.
     * Si la serialización falla, retorna una representación toString() como fallback.
     */
    private String toJson(Map<String, Object> data) {
        if (data == null) return null;
        try {
            return objectMapper.writeValueAsString(data);
        } catch (JsonProcessingException e) {
            log.warn("[AUDIT] No se pudo serializar mapa a JSON: {}", e.getMessage());
            return data.toString(); // Fallback no ideal pero mejor que null
        }
    }
}
