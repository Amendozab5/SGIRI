package com.apweb.backend.controller;

import com.apweb.backend.model.Cliente;
import com.apweb.backend.model.Persona;
import com.apweb.backend.model.Role;
import com.apweb.backend.model.User;
import com.apweb.backend.payload.request.ChangePasswordRequest;
import com.apweb.backend.payload.request.ForgotPasswordRequest;
import com.apweb.backend.payload.request.LoginRequest;
import com.apweb.backend.payload.request.ResetPasswordRequest;
import com.apweb.backend.payload.response.JwtResponse;
import com.apweb.backend.payload.response.MessageResponse;
import com.apweb.backend.repository.ClienteRepository;
import com.apweb.backend.repository.RoleRepository;
import com.apweb.backend.repository.UserRepository;
import com.apweb.backend.repository.PersonaRepository;
import com.apweb.backend.repository.CatalogoItemRepository;
import com.apweb.backend.security.jwt.JwtUtils;
import com.apweb.backend.service.AuditService;
import com.apweb.backend.service.MailService;
import com.apweb.backend.service.PasswordResetService;
import com.apweb.backend.service.UserService;
import com.apweb.backend.util.AuditAccion;
import jakarta.transaction.Transactional;
import jakarta.validation.Valid;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import jakarta.persistence.Query;

import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private static final Logger log = LoggerFactory.getLogger(AuthController.class);

    private final AuthenticationManager authenticationManager;
    private final UserRepository userRepository;
    private final RoleRepository roleRepository;
    private final JwtUtils jwtUtils;
    private final MailService mailService;
    private final ClienteRepository clienteRepository;
    private final PersonaRepository personaRepository;
    private final CatalogoItemRepository catalogoItemRepository;
    private final AuditService auditService;
    private final UserService userService;
    private final PasswordResetService passwordResetService;

    @PersistenceContext
    private EntityManager entityManager;

    public AuthController(AuthenticationManager authenticationManager,
            UserRepository userRepository,
            RoleRepository roleRepository,
            JwtUtils jwtUtils,
            MailService mailService,
            ClienteRepository clienteRepository,
            PersonaRepository personaRepository,
            CatalogoItemRepository catalogoItemRepository,
            AuditService auditService,
            UserService userService,
            PasswordResetService passwordResetService) {
        this.authenticationManager = authenticationManager;
        this.userRepository = userRepository;
        this.roleRepository = roleRepository;
        this.jwtUtils = jwtUtils;
        this.mailService = mailService;
        this.clienteRepository = clienteRepository;
        this.personaRepository = personaRepository;
        this.catalogoItemRepository = catalogoItemRepository;
        this.auditService = auditService;
        this.userService = userService;
        this.passwordResetService = passwordResetService;
    }

    @PostMapping("/login")
    public ResponseEntity<?> authenticateUser(@Valid @RequestBody LoginRequest loginRequest) {
        Authentication authentication;
        try {
            authentication = authenticationManager.authenticate(
                    new UsernamePasswordAuthenticationToken(loginRequest.getUsername(), loginRequest.getPassword()));
        } catch (Exception e) {
            // ── AUDITORÍA: Login fallido ─────────────────────────────────────
            auditService.registrarLoginFallido(
                    loginRequest.getUsername(),
                    "Credenciales incorrectas o cuenta no activada");
            // ────────────────────────────────────────────────────────────────
            return ResponseEntity
                    .status(HttpStatus.UNAUTHORIZED)
                    .body(new MessageResponse("Error: Credenciales incorrectas o cuenta no activada."));
        }

        SecurityContextHolder.getContext().setAuthentication(authentication);
        String jwt = jwtUtils.generateJwtToken(authentication);

        UserDetails userDetails = (UserDetails) authentication.getPrincipal();
        User user = userRepository.findByUsername(userDetails.getUsername())
                .orElseThrow(() -> new RuntimeException(
                        "Error: Usuario no encontrado en la base de datos después de la autenticación."));

        List<String> roles = userDetails.getAuthorities().stream()
                .map(item -> item.getAuthority())
                .collect(Collectors.toList());

        String email = getEmailForUser(user);

        // ── AUDITORÍA: Login exitoso ─────────────────────────────────────────
        // Resolver usuario_bd: CustomUserDetails expone dbUsername para empleados;
        // Clientes no tienen usuario físico — se guarda null y AuditService lo maneja.
        String dbUsername = null;
        if (userDetails instanceof com.apweb.backend.security.jwt.CustomUserDetails customUserDetails) {
            dbUsername = customUserDetails.getDbUsername();
        }
        auditService.registrarLoginExitoso(user.getUsername(), dbUsername, user.getId());
        // ────────────────────────────────────────────────────────────────────

        return ResponseEntity.ok(new JwtResponse(jwt,
                user.getId(),
                user.getUsername(),
                email,
                roles,
                user.getPrimerLogin(),
                user.getIdEmpresa()));
    }

    @PostMapping("/register")
    @Transactional
    public ResponseEntity<?> registerUser(@RequestBody Map<String, Object> signUpRequest) {
        log.info("Received registration request map: {}", signUpRequest);
        try {
            String cedula = (String) signUpRequest.get("cedula");
            Object idEmpresaObj = signUpRequest.get("idEmpresa");
            Integer idEmpresa = null;

            if (idEmpresaObj != null) {
                try {
                    idEmpresa = Integer.valueOf(idEmpresaObj.toString());
                } catch (NumberFormatException e) {
                    log.error("Could not parse idEmpresa: {}", idEmpresaObj);
                }
            }

            if (cedula == null || idEmpresa == null) {
                return ResponseEntity.badRequest().body(new MessageResponse("Error: Cédula y Empresa son requeridos."));
            }

            log.info("Attempting registration for cedula: {} and idEmpresa: {}", cedula, idEmpresa);

            // 1. Verificar si la persona existe en el sistema
            Optional<Persona> personaOpt = personaRepository.findByCedula(cedula);
            if (personaOpt.isEmpty()) {
                log.warn("Persona not found for cedula: {}", cedula);
                return ResponseEntity.badRequest().body(new MessageResponse(
                        "Error: Sus datos no han sido pre-registrados por su proveedor de internet. Por favor, contacte a soporte."));
            }

            Persona persona = personaOpt.get();

            // 2. Verificar si ya tiene un usuario registrado
            if (persona.getUser() != null) {
                log.warn("User already exists for persona with cedula: {}", cedula);
                return ResponseEntity.badRequest()
                        .body(new MessageResponse("Error: Esta persona ya tiene un usuario registrado en el sistema."));
            }

            // 3. Verificar si es cliente de la empresa seleccionada
            Optional<Cliente> clienteOpt = clienteRepository.findByPersona_Cedula(cedula);
            if (clienteOpt.isEmpty()) {
                log.warn("No client record found for persona with cedula: {}", cedula);
                return ResponseEntity.badRequest().body(new MessageResponse(
                        "Error: Usted no aparece registrado como cliente en el sistema."));
            }

            Cliente cliente = clienteOpt.get();
            if (cliente.getSucursal() == null || cliente.getSucursal().getEmpresa() == null) {
                log.warn("Client data is incomplete (missing sucursal or empresa) for cedula: {}", cedula);
                return ResponseEntity.badRequest().body(new MessageResponse(
                        "Error: Sus datos de afiliación están incompletos. Contacte a soporte."));
            }

            if (!cliente.getSucursal().getEmpresa().getId().equals(idEmpresa)) {
                log.warn("ISP Mismatch: Selected ID {}, but database says ID {}", idEmpresa,
                        cliente.getSucursal().getEmpresa().getId());
                return ResponseEntity.badRequest().body(new MessageResponse(
                        "Error: Usted no aparece registrado como cliente en la empresa seleccionada. Por favor, verifique su proveedor de internet."));
            }

            // Continuar con la creación del usuario si todo es válido
            // Llamar a las funciones de PostgreSQL para obtener el username y password
            // según las nuevas reglas de la base de datos "virgen"
            int anioNacimiento = (persona.getFechaNacimiento() != null) ? persona.getFechaNacimiento().getYear() : 1990;

            Query query = entityManager.createNativeQuery(
                    "SELECT f.r_username, f.r_password_plano, f.r_password_hash FROM usuarios.fn_generar_credenciales(:cedula, :anio) f");
            query.setParameter("cedula", persona.getCedula());
            query.setParameter("anio", anioNacimiento);

            Object[] results = (Object[]) query.getSingleResult();
            String generatedUsername = (String) results[0];
            String tempPassword = (String) results[1]; // Password plano para el correo
            String passwordHash = (String) results[2]; // Password ya hasheado por la DB

            Role userRole = roleRepository.findByCodigo("CLIENTE")
                    .orElseThrow(() -> new RuntimeException(
                            "Error: Rol 'CLIENTE' no encontrado en la base de datos. Verifique la tabla usuarios.rol."));

            com.apweb.backend.model.CatalogoItem estadoActivo = catalogoItemRepository.findFirstByCodigo("ACTIVO")
                    .orElseThrow(() -> new RuntimeException("Error: Estado 'ACTIVO' no encontrado."));

            User user = new User();
            user.setUsername(generatedUsername);
            user.setPassword(passwordHash); // Usamos el hash que generó la DB
            user.setRole(userRole);
            user.setEstado(estadoActivo);
            user.setPrimerLogin(true);
            user.setIdEmpresa(idEmpresa);

            User savedUser = userRepository.save(user);

            // Actualizar la persona para vincularla al nuevo usuario
            persona.setUser(savedUser);
            personaRepository.save(persona);

            log.info("User created successfully: {}. Attempting to send welcome email...", generatedUsername);

            try {
                String subject = "Bienvenido a Nuestro Servicio - Sus Credenciales";
                String body = mailService.getWelcomeEmailTemplate(persona.getNombre(), generatedUsername, tempPassword, false);
                mailService.sendEmail(persona.getCorreo(), subject, body);
                log.info("Welcome email sent to {}", persona.getCorreo());
            } catch (Exception mailError) {
                log.error("Could not send welcome email, but user was created: {}", mailError.getMessage());
            }

            return ResponseEntity.ok(new MessageResponse(
                    "Registro exitoso. Bienvenido " + persona.getNombre() + ". Su usuario es: " + generatedUsername));
        } catch (Exception e) {
            log.error("Registration failed: {}", e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(new MessageResponse("Error interno: " + e.getMessage()));
        }
    }

    @PostMapping("/change-password")
    @Transactional
    public ResponseEntity<?> changePassword(@Valid @RequestBody ChangePasswordRequest changePasswordRequest) {
        UserDetails userDetails = (UserDetails) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        User user = userRepository.findByUsername(userDetails.getUsername())
                .orElseThrow(() -> new RuntimeException("Error: Usuario no encontrado."));

        try {
            userService.changePassword(user, changePasswordRequest.getOldPassword(), changePasswordRequest.getNewPassword());
            return ResponseEntity.ok(new MessageResponse("Contraseña cambiada exitosamente."));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(new MessageResponse(e.getMessage()));
        }
    }

    @PostMapping("/logout")
    public ResponseEntity<?> logoutUser() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth != null && auth.getPrincipal() instanceof UserDetails userDetails) {
            User user = userRepository.findByUsername(userDetails.getUsername()).orElse(null);
            if (user != null) {
                auditService.registrarEventoInterno("AUTH", null, null, null, 
                        AuditAccion.LOGOUT, "Cierre de sesión de usuario", null, null, 
                        user.getId(), true, null);
            }
        }
        return ResponseEntity.ok(new MessageResponse("Logout exitoso."));
    }

    @PostMapping("/forgot-password")
    public ResponseEntity<?> forgotPassword(@Valid @RequestBody ForgotPasswordRequest request) {
        try {
            passwordResetService.createPasswordResetTokenForUser(request.getEmail());
            return ResponseEntity.ok(new MessageResponse("Se ha enviado un correo de recuperación si la cuenta existe."));
        } catch (Exception e) {
            log.error("Error in forgot-password: {}", e.getMessage());
            // Por seguridad, devolvemos OK incluso si el correo no existe para evitar enumeración de usuarios
            // Pero si es un error real de infraestructura, podríamos querer saberlo.
            return ResponseEntity.ok(new MessageResponse("Si el correo está registrado, recibirás un enlace de recuperación."));
        }
    }

    @PostMapping("/reset-password")
    public ResponseEntity<?> resetPassword(@Valid @RequestBody ResetPasswordRequest request) {
        try {
            passwordResetService.changeUserPassword(request.getToken(), request.getNewPassword());
            return ResponseEntity.ok(new MessageResponse("Contraseña actualizada exitosamente."));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(new MessageResponse(e.getMessage()));
        }
    }

    private String getEmailForUser(User user) {
        return personaRepository.findByUser(user).map(Persona::getCorreo).orElse(null);
    }
}
