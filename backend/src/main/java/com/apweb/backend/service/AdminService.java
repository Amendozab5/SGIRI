package com.apweb.backend.service;

import com.apweb.backend.model.Role;
import com.apweb.backend.model.User;
import com.apweb.backend.payload.request.UserCreateRequest;
import com.apweb.backend.payload.request.UserUpdateRequest;
import com.apweb.backend.payload.response.UserAdminView;
import com.apweb.backend.repository.RoleRepository;
import com.apweb.backend.repository.UserRepository;
import com.apweb.backend.repository.PersonaRepository;
import com.apweb.backend.repository.EmpleadoRepository;
import com.apweb.backend.repository.ClienteRepository;
import com.apweb.backend.repository.UsuarioBdRepository;
import com.apweb.backend.repository.CatalogoItemRepository;
import com.apweb.backend.model.CatalogoItem;
import com.apweb.backend.model.Persona;
import com.apweb.backend.model.UsuarioBd;
import com.apweb.backend.util.AuditAccion;
import com.apweb.backend.util.AuditModulo;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Collections;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

@Service
public class AdminService {

    private static final Logger log = LoggerFactory.getLogger(AdminService.class);

    /**
     * Roles que corresponden a empleados del sistema.
     * Para estos roles el sistema invoca usuarios.fn_crear_usuario_empleado(...)
     * que crea automáticamente el usuario físico de PostgreSQL y registra
     * la relación en usuarios.usuario_bd, completando la cadena de trazabilidad.
     *
     * El rol CLIENTE usa la Ruta B (JPA), sin usuario físico BD, porque
     * los clientes se auto-registran por otro flujo (/api/auth/register).
     */
    private static final Set<String> EMPLOYEE_ROLES = Set.of(
            "TECNICO", "ADMIN_TECNICOS", "ADMIN_MASTER", "ADMIN_VISUAL");

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private RoleRepository roleRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Autowired
    private PersonaRepository personaRepository;

    @Autowired
    private CatalogoItemRepository catalogoItemRepository;

    @Autowired
    private EmpleadoRepository empleadoRepository;

    @Autowired
    private ClienteRepository clienteRepository;

    @Autowired
    private UsuarioBdRepository usuarioBdRepository;

    @Autowired
    private AuditService auditService;

    @PersistenceContext
    private EntityManager entityManager;

    // -------------------------------------------------------------------------
    // Consultas de administración
    // -------------------------------------------------------------------------

    @Transactional(readOnly = true)
    public List<UserAdminView> getAllUsersForAdmin(String roleName) {
        List<User> users;
        if (roleName != null && !roleName.isEmpty() && !roleName.equalsIgnoreCase("all")) {
            String dbRoleName = roleName.startsWith("ROLE_") ? roleName.substring(5) : roleName;
            Role role = roleRepository.findByCodigoIgnoreCase(dbRoleName)
                    .orElseThrow(() -> new RuntimeException("Error: Role is not found."));
            users = userRepository.findByRole(role);
        } else {
            users = userRepository.findAll();
        }
        return users.stream()
                .map(this::mapToUserAdminView)
                .collect(Collectors.toList());
    }

    public List<String> getRoles() {
        return roleRepository.findAll().stream()
                .map(Role::getCodigo)
                .collect(Collectors.toList());
    }

    // -------------------------------------------------------------------------
    // Creación de usuario
    // -------------------------------------------------------------------------

    /**
     * Crea un usuario del aplicativo.
     *
     * Ruta A — Roles de empleado (TECNICO, ADMIN_*):
     * Invoca usuarios.fn_crear_usuario_empleado(cedula, anio, idRol, idEmpresa,
     * idEstado).
     * Esto crea automáticamente:
     * 1. El usuario en usuarios.usuario
     * 2. La relación en usuarios.usuario_empleado
     * 3. El usuario físico PostgreSQL: emp_{cedula}_{id_usuario}
     * 4. GRANT del rol BD (ej. rol_tecnico TO emp_{cedula}_{id})
     * 5. El registro en usuarios.usuario_bd
     * Con esto el SET ROLE del ConnectionInvocationHandler tiene efecto real.
     *
     * Ruta B — Rol CLIENTE:
     * Crea el usuario por JPA (sin usuario físico BD).
     * Los clientes se auto-registran vía /api/auth/register; el administrador
     * raramente crea clientes manualmente. La trazabilidad se resuelve por
     * id_usuario.
     */
    /**
     * Crea un usuario del aplicativo.
     *
     * Desde la refactorización Opción B, este método Únicamente atiende
     * la creación de usuarios CLIENTE (Ruta B — JPA).
     * Los usuarios empleado se crean a través de
     * {@link #crearUsuarioEmpleado(String, Integer, String, Integer)} invocado
     * directamente desde PersonnelService vía el endpoint dedicado
     * {@code POST /api/personnel/empleados/{cedula}/activar-acceso}.
     */
    @Transactional
    public UserAdminView createUser(UserCreateRequest request) {
        String roleCode = normalizeRoleCode(request.getRole());
        
        // Asegurar idEmpresa si viene nulo del frontend
        if (request.getIdEmpresa() == null) {
            request.setIdEmpresa(1); // Default a empresa 1
            log.warn("[ADMIN] idEmpresa no proporcionado en la creación. Usando default 1.");
        }

        UserAdminView result;

        if (EMPLOYEE_ROLES.contains(roleCode)) {
            // Ruta A: Empleados (Automático via DB)
            result = crearUsuarioEmpleado(
                request.getCedula(), 
                0, // Año de nacimiento (No usado por el SP, pasamos 0)
                roleCode, 
                request.getIdEmpresa()
            );
        } else {
            // Ruta B: Clientes (Automático via DB - fn_crear_usuario_cliente)
            result = createClientUser(request, roleCode);
        }

        // ── AUDITORÍA: Registro Usuario ─────────────────────────────────────
        auditService.registrarEventoContextual(
                AuditModulo.USUARIOS,
                "usuarios", "usuario",
                result.getId(),
                AuditAccion.REGISTRO_USUARIO,
                "Creación administrativa de cuenta (" + roleCode + ")",
                null,
                java.util.Map.of("username", result.getUsername(), "rol", roleCode)
        );
        // ─────────────────────────────────────────────────────────────────────

        return result;
    }

    /**
     * Habilita el acceso al sistema para un empleado existente.
     *
     * Invoca {@code usuarios.fn_crear_usuario_empleado(...)} que de forma atómica:
     * <ol>
     * <li>Valida que la persona+empleado exista y tenga documento ACTIVO</li>
     * <li>Genera username y contraseña temporal</li>
     * <li>Crea el registro en {@code usuarios.usuario}</li>
     * <li>Vincula en {@code usuarios.usuario_empleado}</li>
     * <li>Crea el usuario físico PostgreSQL {@code emp_{cedula}_{id}}</li>
     * <li>Le asigna el rol BD correspondiente y hace GRANT a sgiri_app</li>
     * <li>Registra en {@code usuarios.usuario_bd}</li>
     * </ol>
     *
     * @param cedula         Cédula del empleado (ya debe existir en
     *                       empleados.empleado)
     * @param anioNacimiento Año de nacimiento para construcción de contraseña
     *                       temporal
     * @param roleCode       Código del rol aplicativo (TECNICO, ADMIN_MASTER, etc.)
     * @param idEmpresa      ID de la empresa para usuarios.usuario.id_empresa
     * @return Vista admin del usuario creado
     */
    @Transactional
    public UserAdminView crearUsuarioEmpleado(String cedula, Integer anioNacimiento,
            String roleCode, Integer idEmpresa) {
        String normalizedRole = normalizeRoleCode(roleCode);

        if (!EMPLOYEE_ROLES.contains(normalizedRole)) {
            throw new IllegalArgumentException(
                    "El rol '" + roleCode + "' no corresponde a un rol de empleado. " +
                            "Roles válidos: " + EMPLOYEE_ROLES);
        }

        Role role = roleRepository.findByCodigo(normalizedRole)
                .orElseThrow(() -> new RuntimeException(
                        "Error: Rol '" + normalizedRole + "' no encontrado en la base de datos."));

        CatalogoItem estadoActivo = catalogoItemRepository.findFirstByCodigo("ACTIVO")
                .orElseThrow(() -> new RuntimeException(
                        "Error: Estado 'ACTIVO' no encontrado en el catálogo."));

        log.info("[TRAZABILIDAD] Activando acceso empleado: cedula={}, rol={}, empresa={}",
                cedula, normalizedRole, idEmpresa);

        Object[] result;
        try {
            result = (Object[]) entityManager.createNativeQuery(
                    "SELECT r_id_usuario, r_username, r_password_plano FROM usuarios.fn_crear_usuario_empleado(:cedula, :anio, :idRol, :idEmpresa, :idEstado)")
                    .setParameter("cedula", cedula)
                    .setParameter("anio", anioNacimiento)
                    .setParameter("idRol", role.getId())
                    .setParameter("idEmpresa", idEmpresa)
                    .setParameter("idEstado", estadoActivo.getId())
                    .getSingleResult();
        } catch (Exception ex) {
            String msg = ex.getMessage() != null ? ex.getMessage() : ex.getClass().getSimpleName();
            log.error("[TRAZABILIDAD] Error al activar acceso cedula={}: {}", cedula, msg);
            throw new RuntimeException(translateEmployeeCreationError(msg, cedula, normalizedRole));
        }

        Integer idUsuarioCreado = (Integer) result[0];
        String tempPass = (String) result[2];

        User savedUser = userRepository.findById(idUsuarioCreado)
                .orElseThrow(() -> new RuntimeException(
                        "Error interno: fn_crear_usuario_empleado devolvió id=" + idUsuarioCreado +
                                " pero el usuario no se encontró en usuarios.usuario."));

        log.info("[TRAZABILIDAD] Acceso activado — app_id={}, username={}, bd_user=emp_{}_{}",
                savedUser.getId(), savedUser.getUsername(), cedula, idUsuarioCreado);

        UserAdminView response = mapToUserAdminView(savedUser);
        response.setTemporaryPassword(tempPass);

        // La auditoría de este flujo se dispara en PersonnelService.activarAccesoEmpleado
        // para mantener consistencia con el flujo de negocio superior.

        return response;
    }

    /**
     * Ruta B (cliente): Crea usuario cliente directamente por JPA.
     * No crea usuario físico en PostgreSQL.
     */
    private UserAdminView createClientUser(UserCreateRequest request, String roleCode) {
        Role role = roleRepository.findByCodigo(roleCode)
                .orElseThrow(() -> new RuntimeException(
                        "Error: Rol '" + roleCode + "' no encontrado."));

        CatalogoItem estadoActivo = catalogoItemRepository.findFirstByCodigo("ACTIVO")
                .orElseThrow(() -> new RuntimeException(
                        "Error: Estado 'ACTIVO' no encontrado."));

        // Validar que tengamos los datos necesarios para fn_crear_usuario_cliente
        // En este flujo, si es creación administrativa, usamos la cédula de la persona si existe,
        // o la del request si se proporciona.
        String cedula = request.getCedula();

        if (cedula == null) {
            // Intentar obtener de la persona si está vinculada (un poco redundante pero seguro)
            // Sin embargo, fn_crear_usuario_cliente REQUIERE la cédula para generar credenciales.
            throw new RuntimeException("Error: La cédula es obligatoria para generar credenciales automáticas del cliente.");
        }

        log.info("[TRAZABILIDAD] Creando usuario cliente vía DB: cedula={}, rol={}, empresa={}",
                cedula, roleCode, request.getIdEmpresa());

        Integer idUsuarioCreado;
        try {
            idUsuarioCreado = (Integer) entityManager.createNativeQuery(
                    "SELECT usuarios.fn_crear_usuario_cliente(:cedula, :anio, :idRol, :idEmpresa, :idEstado)")
                    .setParameter("cedula", cedula)
                    .setParameter("anio", 0) // Año de nacimiento no usado
                    .setParameter("idRol", role.getId())
                    .setParameter("idEmpresa", request.getIdEmpresa())
                    .setParameter("idEstado", estadoActivo.getId())
                    .getSingleResult();
        } catch (Exception ex) {
            String msg = ex.getMessage() != null ? ex.getMessage() : ex.getClass().getSimpleName();
            log.error("[TRAZABILIDAD] Error al crear usuario cliente cedula={}: {}", cedula, msg);
            throw new RuntimeException("Error al crear usuario cliente en DB: " + msg);
        }

        User savedUser = userRepository.findById(idUsuarioCreado)
                .orElseThrow(() -> new RuntimeException(
                        "Error interno: El usuario cliente se creó pero no se encontró con ID=" + idUsuarioCreado));

        log.info("[TRAZABILIDAD] Usuario cliente creado exitosamente — id={}, username={}", 
                savedUser.getId(), savedUser.getUsername());
        
        return mapToUserAdminView(savedUser);
    }

    // -------------------------------------------------------------------------
    // Actualización y eliminación
    // -------------------------------------------------------------------------

    @Transactional
    public void toggleUserStatus(Integer userId, String newStatusCode) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("Error: User not found with id " + userId));

        CatalogoItem status = catalogoItemRepository.findFirstByCodigo(newStatusCode)
                .orElseThrow(() -> new RuntimeException(
                        "Error: Status not found with code " + newStatusCode));

        if (status.getActivo() != null && !status.getActivo()) {
            throw new RuntimeException(
                    "Error: El estado '" + newStatusCode + "' está deshabilitado en el catálogo.");
        }

        String oldStatus = user.getEstado() != null ? user.getEstado().getCodigo() : "N/A";
        user.setEstado(status);
        userRepository.save(user);

        // ── AUDITORÍA: Cambio Estado Usuario ─────────────────────────────────
        auditService.registrarEventoContextual(
                AuditModulo.USUARIOS,
                "usuarios", "usuario",
                user.getId(),
                AuditAccion.CAMBIO_ESTADO,
                "Suspensión o reactivación administrativa de cuenta",
                java.util.Map.of("estado", oldStatus),
                java.util.Map.of("estado", newStatusCode)
        );
        // ─────────────────────────────────────────────────────────────────────
    }

    @Transactional
    public UserAdminView updateUser(Integer userId, UserUpdateRequest request) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("Error: User not found with id " + userId));

        user.setUsername(request.getUsername());

        CatalogoItem status = catalogoItemRepository.findFirstByCodigo(request.getEstado())
                .orElseThrow(() -> new RuntimeException(
                        "Error: Status not found with code " + request.getEstado()));

        if (status.getActivo() != null && !status.getActivo()) {
            throw new RuntimeException(
                    "Error: El estado '" + request.getEstado() + "' está deshabilitado.");
        }

        user.setEstado(status);

        String updateRoleCode = normalizeRoleCode(request.getRole());
        Role userRole = roleRepository.findByCodigo(updateRoleCode)
                .orElseThrow(() -> new RuntimeException("Error: Role is not found."));
        String oldRole = user.getRole().getCodigo();
        user.setRole(userRole);

        User updatedUser = userRepository.save(user);

        // ── AUDITORÍA: Cambio de Rol ─────────────────────────────────────────
        auditService.registrarEventoContextual(
                AuditModulo.USUARIOS,
                "usuarios", "usuario",
                updatedUser.getId(),
                AuditAccion.UPDATE,
                "Cambio administrativo de rol de usuario",
                java.util.Map.of("rol", oldRole),
                java.util.Map.of("rol", updateRoleCode)
        );
        // ─────────────────────────────────────────────────────────────────────

        return mapToUserAdminView(updatedUser);
    }

    @Transactional
    public void deleteUser(Integer userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("Error: User not found with id " + userId));

        Persona persona = user.getPersona();
        boolean isLinkedToPersona = (persona != null);
        boolean isEmployee = (persona != null) && empleadoRepository.existsByPersona_Cedula(persona.getCedula());
        boolean isClient = (persona != null) && clienteRepository.existsByPersona_Cedula(persona.getCedula());

        if (isEmployee && persona != null) {
            log.info("[ADMIN] Revocando acceso para el colaborador (cedula: {}) - userId: {}", persona.getCedula(),
                    userId);

            // ── AUDITORÍA: Captura previa al borrado ─────────────────────────
            String targetUsername = user.getUsername();
            String targetRole = user.getRole().getCodigo();
            List<UsuarioBd> bdUsers = usuarioBdRepository.findByUser_Id(userId);
            String targetBdUser = bdUsers.stream().map(UsuarioBd::getNombre).findFirst().orElse("N/A");
            // ─────────────────────────────────────────────────────────────────

            // 1. Desvincular Persona de Usuario (borrar FK en persona)
            persona.setUser(null);
            personaRepository.save(persona);

            // 2. Eliminar registros en usuarios.usuario_bd y roles físicos de DB
            for (UsuarioBd bdu : bdUsers) {
                String bdUserName = bdu.getNombre();
                usuarioBdRepository.delete(bdu);

                try {
                    // 3. Destruir rol físico en PostgreSQL si existe (evita basura en BD física)
                    entityManager.createNativeQuery("DROP ROLE IF EXISTS " + bdUserName).executeUpdate();
                    log.info("[ADMIN] Rol físico de DB destruido: {}", bdUserName);
                } catch (Exception e) {
                    log.error("[ADMIN] No se pudo borrar el rol físico de DB: {}", e.getMessage());
                }
            }

            // 4. Eliminar el usuario del aplicativo
            userRepository.delete(user);
            log.info("[ADMIN] Acceso de colaborador revocado exitosamente.");

            // ── AUDITORÍA: Registro Final ────────────────────────────────────
            auditService.registrarEventoContextual(
                AuditModulo.USUARIOS,
                "usuarios", "usuario",
                userId,
                AuditAccion.REVOCACION_ACCESO,
                "Revocación total de acceso y destrucción de identidad física",
                java.util.Map.of(
                    "username", targetUsername,
                    "rol", targetRole,
                    "bd_user", targetBdUser
                ),
                null
            );
            // ─────────────────────────────────────────────────────────────────

        } else {
            // Caso Clientes u otros
            if (isLinkedToPersona && persona != null) {
                log.info("[ADMIN] Desvinculando identidad de usuario {} (cedula: {})", userId, persona.getCedula());
                
                // ── AUDITORÍA: Captura previa ─────────────────────────────────
                String targetUsername = user.getUsername();
                String targetRole = user.getRole().getCodigo();
                // ─────────────────────────────────────────────────────────────

                persona.setUser(null);
                personaRepository.save(persona);

                userRepository.delete(user);

                if (!isClient) {
                    try {
                        personaRepository.delete(persona);
                        log.info("[ADMIN] Persona eliminada por no tener otras referencias.");
                    } catch (Exception e) {
                        log.info("[ADMIN] Persona mantenida por restricciones de integridad.");
                    }
                }

                // ── AUDITORÍA: Registro Final ────────────────────────────────────
                auditService.registrarEventoContextual(
                    AuditModulo.USUARIOS,
                    "usuarios", "usuario",
                    userId,
                    AuditAccion.REVOCACION_ACCESO,
                    "Revocación de acceso de usuario cliente",
                    java.util.Map.of("username", targetUsername, "rol", targetRole),
                    null
                );
                // ─────────────────────────────────────────────────────────────────
            } else {
                userRepository.delete(user);
            }
        }
    }

    // -------------------------------------------------------------------------
    // Helpers
    // -------------------------------------------------------------------------

    /** Elimina el prefijo ROLE_ si viene del frontend */
    private String normalizeRoleCode(String role) {
        if (role == null)
            return "";
        return role.startsWith("ROLE_") ? role.substring(5) : role;
    }

    /**
     * Traduce los mensajes de error de PostgreSQL a mensajes legibles en español.
     * Los errores se originan en la función PL/pgSQL fn_crear_usuario_empleado.
     */
    private String translateEmployeeCreationError(String pgMsg, String cedula, String roleCode) {
        if (pgMsg.contains("El empleado no existe")) {
            return "Error: No existe un empleado registrado con la cédula '" + cedula + "'. " +
                    "Asegúrate de que el empleado fue creado primero en el sistema.";
        }
        if (pgMsg.contains("El empleado no tiene documento validado")) {
            return "Error: El empleado con cédula '" + cedula + "' no tiene documentos con estado ACTIVO. " +
                    "Valida los documentos del empleado antes de crear su usuario.";
        }
        if (pgMsg.contains("El rol BD asociado no existe")) {
            return "Error: El rol físico de PostgreSQL para '" + roleCode + "' no existe. " +
                    "Ejecuta el script SQL '01_roles_fisicos_y_permisos.sql' en PostgreSQL primero.";
        }
        if (pgMsg.contains("El rol aplicativo no existe")) {
            return "Error: El rol '" + roleCode + "' no está registrado en usuarios.rol.";
        }
        if (pgMsg.contains("already exists") || pgMsg.contains("ya existe")
                || pgMsg.contains("duplicate key")) {
            return "Error: Ya existe un usuario creado para la cédula '" + cedula + "'.";
        }
        // Error genérico con mensaje original para diagnóstico
        return "Error al crear usuario en la base de datos: " + pgMsg;
    }

    private UserAdminView mapToUserAdminView(User user) {
        String email = "N/A";
        String fullName = "N/A";
        String nombre = "N/A";
        String apellido = "N/A";

        Persona persona = user.getPersona();
        if (persona != null) {
            email = persona.getCorreo();
            nombre = persona.getNombre();
            apellido = persona.getApellido();
            fullName = nombre + " " + apellido;
        }

        List<String> roles = Collections.singletonList(user.getRole().getCodigo());

        return new UserAdminView(
                user.getId(),
                user.getUsername(),
                fullName,
                nombre,
                apellido,
                email,
                roles,
                user.getEstado() != null ? user.getEstado().getCodigo() : "N/A",
                user.getFechaCreacion(),
                user.getFechaActualizacion());
    }
}
