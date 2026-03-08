package com.apweb.backend.service;

import com.apweb.backend.dto.EmpleadoAccessStatusDTO;
import com.apweb.backend.dto.EmpleadoActivarAccesoRequest;
import com.apweb.backend.dto.EmpleadoCreateRequest;
import com.apweb.backend.dto.EmpleadoDTO;
import com.apweb.backend.model.*;
import com.apweb.backend.payload.response.UserAdminView;
import com.apweb.backend.repository.*;
import com.apweb.backend.util.AuditAccion;
import com.apweb.backend.util.AuditModulo;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
public class PersonnelService {

        private static final Logger log = LoggerFactory.getLogger(PersonnelService.class);

        @Autowired
        private PersonaRepository personaRepository;
        @Autowired
        private EmpleadoRepository empleadoRepository;
        @Autowired
        private ClienteRepository clienteRepository;
        @Autowired
        private AreaRepository areaRepository;
        @Autowired
        private CargoRepository cargoRepository;
        @Autowired
        private TipoContratoRepository tipoContratoRepository;
        @Autowired
        private SucursalRepository sucursalRepository;
        @Autowired
        private DocumentoEmpleadoRepository documentoEmpleadoRepository;
        @Autowired
        private UserRepository userRepository;
        @Autowired
        private AdminService adminService;
        @Autowired
        private MailService mailService;
        @Autowired
        private AuditService auditService;

        // ─── Consultas de solo lectura ────────────────────────────────────────────

        @Transactional(readOnly = true)
        public List<Persona> getAllPersonas() {
                return personaRepository.findAll();
        }

        @Transactional(readOnly = true)
        public List<EmpleadoDTO> getAllEmpleados() {
                return empleadoRepository.findAll().stream()
                                .map(this::toDTO)
                                .collect(Collectors.toList());
        }

        @Transactional(readOnly = true)
        public List<Cliente> getAllClientes() {
                return clienteRepository.findAll();
        }

        @Transactional(readOnly = true)
        public Optional<EmpleadoDTO> getEmpleadoByCedula(String cedula) {
                return empleadoRepository.findByPersona_Cedula(cedula).map(this::toDTO);
        }

        @Transactional(readOnly = true)
        public Optional<Cliente> getClienteByCedula(String cedula) {
                return clienteRepository.findByPersona_Cedula(cedula);
        }

        // ─── Creación de Empleado (Fases 1 + 2 del flujo) ────────────────────────

        /**
         * Crea un empleado.
         * <p>
         * Flujo:
         * 1. Busca o crea usuarios.persona por cédula.
         * 2. Valida que esa persona no sea ya un empleado.
         * 3. Resuelve las FKs laborales (cargo, area, tipo_contrato, sucursal).
         * 4. Persiste empleados.empleado.
         * </p>
         */
        @Transactional
        public EmpleadoDTO crearEmpleado(EmpleadoCreateRequest req) {

                // 1. Buscar persona existente o crearla
                Persona persona = personaRepository.findByCedula(req.getCedula())
                                .orElseGet(() -> crearPersona(req));

                // 2. Validar que no sea ya empleado
                if (empleadoRepository.existsByPersona_Cedula(req.getCedula())) {
                        throw new IllegalStateException(
                                        "Ya existe un empleado registrado con la cédula '" + req.getCedula() + "'.");
                }

                // 3. Resolver FKs laborales
                Cargo cargo = cargoRepository.findById(req.getIdCargo())
                                .orElseThrow(() -> new IllegalArgumentException(
                                                "El cargo con id=" + req.getIdCargo() + " no existe."));

                Area area = areaRepository.findById(req.getIdArea())
                                .orElseThrow(() -> new IllegalArgumentException(
                                                "El área con id=" + req.getIdArea() + " no existe."));

                TipoContrato tipoContrato = tipoContratoRepository.findById(req.getIdTipoContrato())
                                .orElseThrow(() -> new IllegalArgumentException(
                                                "El tipo de contrato con id=" + req.getIdTipoContrato()
                                                                + " no existe."));

                // 4. Crear empleado
                Empleado empleado = new Empleado();
                empleado.setPersona(persona);
                empleado.setCargo(cargo);
                empleado.setArea(area);
                empleado.setTipoContrato(tipoContrato);
                empleado.setFechaIngreso(req.getFechaIngreso());

                if (req.getIdSucursal() != null) {
                        Sucursal sucursal = sucursalRepository.findById(req.getIdSucursal())
                                        .orElseThrow(() -> new IllegalArgumentException(
                                                        "La sucursal con id=" + req.getIdSucursal() + " no existe."));
                        empleado.setSucursal(sucursal);
                }

                Empleado guardado = empleadoRepository.save(empleado);
                log.info("[EMPLEADOS] Empleado creado — id={}, cedula={}", guardado.getIdEmpleado(),
                                persona.getCedula());

                // ── AUDITORÍA: Alta Laboral ──────────────────────────────────────────
                auditService.registrarEventoContextual(
                        AuditModulo.EMPLEADOS,
                        "empleados", "empleado",
                        guardado.getIdEmpleado(),
                        AuditAccion.INSERT,
                        "Registro inicial de datos laborales del empleado",
                        null,
                        java.util.Map.of(
                            "cedula", persona.getCedula(),
                            "id_cargo", guardado.getCargo().getId(),
                            "id_area", guardado.getArea().getId()
                        )
                );
                // ────────────────────────────────────────────────────────────────────

                return toDTO(guardado);
        }

        // ─── Verificación de precondiciones para acceso ───────────────────────────

        /**
         * Evalúa todas las precondiciones necesarias para habilitar acceso al sistema
         * a un empleado. El frontend usa esta respuesta para mostrar el estado
         * correcto.
         */
        @Transactional(readOnly = true)
        public EmpleadoAccessStatusDTO getAccessStatus(String cedula) {

                boolean personaExiste = personaRepository.existsByCedula(cedula);
                if (!personaExiste) {
                        return EmpleadoAccessStatusDTO.builder()
                                        .personaExiste(false)
                                        .empleadoExiste(false)
                                        .tieneDocumentoActivo(false)
                                        .yaTieneUsuario(false)
                                        .puedeActivar(false)
                                        .razonBloqueo("No existe ninguna persona registrada con la cédula '" + cedula
                                                        + "'.")
                                        .build();
                }

                Optional<Empleado> empOpt = empleadoRepository.findByPersona_Cedula(cedula);
                if (empOpt.isEmpty()) {
                        return EmpleadoAccessStatusDTO.builder()
                                        .personaExiste(true)
                                        .empleadoExiste(false)
                                        .tieneDocumentoActivo(false)
                                        .yaTieneUsuario(false)
                                        .puedeActivar(false)
                                        .razonBloqueo("La persona existe pero no tiene registro laboral como empleado.")
                                        .build();
                }

                Empleado emp = empOpt.get();
                boolean tieneDocActivo = documentoEmpleadoRepository
                                .existsByEmpleado_IdEmpleadoAndEstado_Codigo(emp.getIdEmpleado(), "ACTIVO");

                // Verificar si ya tiene usuario en el sistema
                Optional<User> userOpt = userRepository.findByPersona_Cedula(cedula);

                boolean yaTieneUsuario = userOpt.isPresent();
                String usernameExistente = userOpt.map(User::getUsername).orElse(null);
                String codigoEstadoUsuario = userOpt.map(u -> u.getEstado() != null ? u.getEstado().getCodigo() : null).orElse(null);
                String nombreEstadoUsuario = userOpt.map(u -> u.getEstado() != null ? u.getEstado().getNombre() : null).orElse(null);

                boolean puedeActivar = tieneDocActivo && !yaTieneUsuario;
                String razon = null;
                if (!tieneDocActivo) {
                        razon = "El empleado no tiene documentos con estado ACTIVO. Suba y valide un documento primero.";
                } else if (yaTieneUsuario) {
                        if ("INACTIVO".equals(codigoEstadoUsuario)) {
                                razon = "El acceso del empleado está suspendido por falta de documentación válida.";
                        } else {
                                razon = "El empleado ya tiene acceso al sistema (username: " + usernameExistente + ").";
                        }
                }

                return EmpleadoAccessStatusDTO.builder()
                                .personaExiste(true)
                                .empleadoExiste(true)
                                .tieneDocumentoActivo(tieneDocActivo)
                                .yaTieneUsuario(yaTieneUsuario)
                                .puedeActivar(puedeActivar)
                                .usernameExistente(usernameExistente)
                                .codigoEstadoUsuario(codigoEstadoUsuario)
                                .nombreEstadoUsuario(nombreEstadoUsuario)
                                .razonBloqueo(razon)
                                .build();
        }

        // ── Activación de acceso al sistema ──────────────────────────────────────

        /**
         * Habilita el acceso al sistema para un empleado existente.
         *
         * <p>
         * Precondiciones (validadas internamente por fn_crear_usuario_empleado):
         * </p>
         * <ul>
         * <li>La cédula debe existir en {@code usuarios.persona} Y en
         * {@code empleados.empleado}</li>
         * <li>El empleado debe tener al menos un documento con estado ACTIVO</li>
         * <li>No debe existir ya un usuario vinculado a ese empleado</li>
         * </ul>
         *
         * <p>
         * Delega en {@link AdminService#crearUsuarioEmpleado} que invoca
         * {@code usuarios.fn_crear_usuario_empleado(...)} de forma atómica.
         * </p>
         */
        @Transactional
        public UserAdminView activarAccesoEmpleado(
                        String cedula, EmpleadoActivarAccesoRequest req) {

                // 1. Validar previamente que el empleado exista
                Empleado empleado = empleadoRepository.findByPersona_Cedula(cedula)
                                .orElseThrow(() -> new IllegalArgumentException(
                                                "No existe ningún empleado registrado con la cédula '" + cedula + "'. " +
                                                                "Complete primero el alta laboral antes de activar el acceso."));

                // 2. Ejecutar creación (SQL + Rol físico)
                UserAdminView createdUser = adminService.crearUsuarioEmpleado(
                                cedula,
                                req.getAnioNacimiento(),
                                req.getRol(),
                                req.getIdEmpresa());

                // 3. Intentar envío de correo (No transaccional para evitar rollback por falla de red/mail)
                try {
                        Persona p = empleado.getPersona();
                        if (p.getCorreo() != null && !p.getCorreo().isBlank()) {
                                String subject = "Bienvenido al Equipo SGIM - Tus Credenciales de Acceso";
                                String body = mailService.getWelcomeEmailTemplate(
                                                p.getNombre(),
                                                createdUser.getUsername(),
                                                createdUser.getTemporaryPassword(),
                                                true);
                                mailService.sendEmail(p.getCorreo(), subject, body);
                                createdUser.setEmailSent(true);
                                log.info("[EMPLEADOS] Correo de bienvenida enviado a {} para el usuario {}", 
                                        p.getCorreo(), createdUser.getUsername());
                        } else {
                                createdUser.setEmailSent(false);
                                log.warn("[EMPLEADOS] No se pudo enviar correo de bienvenida: El empleado con cédula {} no tiene correo registrado.", cedula);
                        }
                } catch (Exception e) {
                        createdUser.setEmailSent(false);
                        log.error("[EMPLEADOS] Error al enviar correo de bienvenida para {}: {}", 
                                createdUser.getUsername(), e.getMessage());
                }

                // ── AUDITORÍA: Activación de Acceso ──────────────────────────────────
                // Registramos después de la lógica principal para asegurar el éxito del flujo.
                auditService.registrarEventoContextual(
                        AuditModulo.USUARIOS,
                        "usuarios", "usuario",
                        createdUser.getId(),
                        AuditAccion.ACTIVACION_ACCESO,
                        "Activación de acceso y creación de rol físico SQL",
                        null,
                        java.util.Map.of(
                            "username", createdUser.getUsername(),
                            "rol", req.getRol(),
                            "id_empleado", empleado.getIdEmpleado()
                        )
                );
                // ────────────────────────────────────────────────────────────────────

                return createdUser;
        }

        // ─── Helpers ─────────────────────────────────────────────────────────────

        /**
         * Crea una nueva persona en usuarios.persona a partir de los datos del request.
         * Solo se llama si la cédula no existe aún en el sistema.
         */
        private Persona crearPersona(EmpleadoCreateRequest req) {
                if (req.getNombre() == null || req.getNombre().isBlank()) {
                        throw new IllegalArgumentException(
                                        "La persona con cédula '" + req.getCedula() + "' no existe. " +
                                                        "Se requieren 'nombre' y 'apellido' para crearla.");
                }
                if (req.getApellido() == null || req.getApellido().isBlank()) {
                        throw new IllegalArgumentException(
                                        "La persona con cédula '" + req.getCedula() + "' no existe. " +
                                                        "Se requieren 'nombre' y 'apellido' para crearla.");
                }

                Persona p = Persona.builder()
                                .cedula(req.getCedula())
                                .nombre(req.getNombre())
                                .apellido(req.getApellido())
                                .correo(req.getCorreo())
                                .celular(req.getCelular())
                                .fechaNacimiento(req.getFechaNacimiento())
                                .build();

                Persona guardada = personaRepository.save(p);
                log.info("[EMPLEADOS] Persona creada durante registro de empleado — cedula={}", req.getCedula());
                return guardada;
        }

        /**
         * Convierte un Empleado JPA a EmpleadoDTO añadiendo indicadores de estado.
         */
        public EmpleadoDTO toDTO(Empleado e) {
                Persona p = e.getPersona();

                boolean tieneDocActivo = e.getIdEmpleado() != null &&
                                documentoEmpleadoRepository.existsByEmpleado_IdEmpleadoAndEstado_Codigo(
                                                e.getIdEmpleado(), "ACTIVO");

                Optional<User> userOpt = (p != null) ? userRepository.findByPersona(p) : Optional.empty();

                boolean tieneUsuario = userOpt.isPresent();
                String username = userOpt.map(User::getUsername).orElse(null);
                String estadoUsuario = userOpt.map(u -> u.getEstado() != null ? u.getEstado().getCodigo() : null).orElse(null);

                return EmpleadoDTO.builder()
                                .idEmpleado(e.getIdEmpleado())
                                .cedula(p != null ? p.getCedula() : null)
                                .nombre(p != null ? p.getNombre() : null)
                                .apellido(p != null ? p.getApellido() : null)
                                .correo(p != null ? p.getCorreo() : null)
                                .celular(p != null ? p.getCelular() : null)
                                .fechaNacimiento(p != null ? p.getFechaNacimiento() : null)
                                .fechaIngreso(e.getFechaIngreso())
                                .idArea(e.getArea() != null ? e.getArea().getId() : null)
                                .nombreArea(e.getArea() != null ? e.getArea().getNombre() : null)
                                .idCargo(e.getCargo() != null ? e.getCargo().getId() : null)
                                .nombreCargo(e.getCargo() != null ? e.getCargo().getNombre() : null)
                                .idTipoContrato(e.getTipoContrato() != null ? e.getTipoContrato().getId() : null)
                                .nombreTipoContrato(
                                                e.getTipoContrato() != null ? e.getTipoContrato().getNombre() : null)
                                .idSucursal(e.getSucursal() != null ? e.getSucursal().getId() : null)
                                .nombreSucursal(e.getSucursal() != null ? e.getSucursal().getNombre() : null)
                                .tieneDocumentoActivo(tieneDocActivo)
                                .tieneUsuarioActivo(tieneUsuario && "ACTIVO".equals(estadoUsuario))
                                .usernameSistema(username)
                                .codigoEstadoUsuario(estadoUsuario)
                                .build();
        }
}
