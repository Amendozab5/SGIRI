package com.apweb.backend.controller;

import com.apweb.backend.model.Cliente;
import com.apweb.backend.model.Role;
import com.apweb.backend.model.User;
import com.apweb.backend.model.UsuarioCliente;
import com.apweb.backend.payload.request.ChangePasswordRequest;
import com.apweb.backend.payload.request.ForgotPasswordRequest;
import com.apweb.backend.payload.request.LoginRequest;
import com.apweb.backend.payload.request.ResetPasswordRequest;
import com.apweb.backend.payload.response.JwtResponse;
import com.apweb.backend.payload.response.MessageResponse;
import com.apweb.backend.repository.ClienteRepository;
import com.apweb.backend.repository.RoleRepository;
import com.apweb.backend.repository.UsuarioClienteRepository;
import com.apweb.backend.repository.UserRepository;
import com.apweb.backend.security.jwt.JwtUtils;
import com.apweb.backend.service.MailService;
import com.apweb.backend.service.UserDetailsServiceImpl;
import jakarta.transaction.Transactional;
import jakarta.validation.Valid;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Random;
import java.util.UUID;
import java.util.stream.Collectors;

@CrossOrigin(origins = "*", maxAge = 3600)
@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private static final Logger log = LoggerFactory.getLogger(AuthController.class);

    private final AuthenticationManager authenticationManager;
    private final UserRepository userRepository;
    private final RoleRepository roleRepository;
    private final PasswordEncoder encoder;
    private final JwtUtils jwtUtils;
    private final MailService mailService;
    private final ClienteRepository clienteRepository;
    private final UsuarioClienteRepository usuarioClienteRepository;

    public AuthController(AuthenticationManager authenticationManager,
                          UserRepository userRepository,
                          RoleRepository roleRepository,
                          PasswordEncoder encoder,
                          JwtUtils jwtUtils,
                          MailService mailService,
                          ClienteRepository clienteRepository,
                          UsuarioClienteRepository usuarioClienteRepository) {
        this.authenticationManager = authenticationManager;
        this.userRepository = userRepository;
        this.roleRepository = roleRepository;
        this.encoder = encoder;
        this.jwtUtils = jwtUtils;
        this.mailService = mailService;
        this.clienteRepository = clienteRepository;
        this.usuarioClienteRepository = usuarioClienteRepository;
    }

    @PostMapping("/login")
    public ResponseEntity<?> authenticateUser(@Valid @RequestBody LoginRequest loginRequest) {
        Authentication authentication;
        try {
            authentication = authenticationManager.authenticate(
                    new UsernamePasswordAuthenticationToken(loginRequest.getUsername(), loginRequest.getPassword()));
        } catch (Exception e) {
            return ResponseEntity
                    .status(HttpStatus.UNAUTHORIZED)
                    .body(new MessageResponse("Error: Credenciales incorrectas o cuenta no activada."));
        }

        SecurityContextHolder.getContext().setAuthentication(authentication);
        String jwt = jwtUtils.generateJwtToken(authentication);

        UserDetails userDetails = (UserDetails) authentication.getPrincipal();
        User user = userRepository.findByUsername(userDetails.getUsername())
                .orElseThrow(() -> new RuntimeException("Error: Usuario no encontrado en la base de datos después de la autenticación."));

        List<String> roles = userDetails.getAuthorities().stream()
                .map(item -> item.getAuthority())
                .collect(Collectors.toList());
        
        String email = getEmailForUser(user);

        return ResponseEntity.ok(new JwtResponse(jwt,
                user.getId(),
                user.getUsername(),
                email,
                roles,
                user.getProfilePictureUrl(),
                user.getPrimerLogin()));
    }

    @PostMapping("/register")
    @Transactional
    public ResponseEntity<?> registerUser(@RequestBody Map<String, Object> signUpRequest) {
        log.info("Received registration request map: {}", signUpRequest);
        try {
            String cedula = (String) signUpRequest.get("cedula");
            String email = (String) signUpRequest.get("email");
            String nombres = (String) signUpRequest.get("nombres");
            String apellidos = (String) signUpRequest.get("apellidos");
            String direccion = (String) signUpRequest.get("direccion");
            Integer idCanton = (Integer) signUpRequest.get("idCanton");

            if (idCanton == null) {
                log.warn("Registration failed: idCanton is null for user {}", signUpRequest.get("username"));
                return ResponseEntity
                        .badRequest()
                        .contentType(org.springframework.http.MediaType.APPLICATION_JSON)
                        .body(new MessageResponse("Error: El campo idCanton es nulo o no se está enviando correctamente."));
            }

            if (clienteRepository.existsByCedula(cedula)) {
                log.warn("Registration failed: Cedula {} already exists.", cedula);
                return ResponseEntity
                        .badRequest()
                        .contentType(org.springframework.http.MediaType.APPLICATION_JSON)
                        .body(new MessageResponse("Error: La cédula ya está registrada."));
            }

            if (clienteRepository.existsByCorreo(email)) {
                log.warn("Registration failed: Email {} already in use.", email);
                return ResponseEntity
                        .badRequest()
                        .contentType(org.springframework.http.MediaType.APPLICATION_JSON)
                        .body(new MessageResponse("Error: El correo electrónico ya está en uso."));
            }

            String generatedUsername = userRepository.generarUsernameUnico(nombres, apellidos);

            Cliente cliente = new Cliente();
            cliente.setCedula(cedula);
            cliente.setNombres(nombres);
            cliente.setApellidos(apellidos);
            cliente.setCelular((String) signUpRequest.get("numeroTelefonico"));
            cliente.setCorreo(email);
            cliente.setDireccion(direccion);
            cliente.setIdCanton(idCanton);
            cliente.setEstadoServicio("ACTIVO");
            cliente.setIdEmpresa(1); // Hardcoded default value

            Cliente savedCliente = clienteRepository.save(cliente);

            String tempPassword = generateTemporaryPassword(cedula);
            Role userRole = roleRepository.findByCodigo("ROLE_USER")
                    .orElseThrow(() -> new RuntimeException("Error: Rol 'ROLE_USER' no encontrado."));

            User user = new User();
            user.setUsername(generatedUsername);
            user.setPassword(encoder.encode(tempPassword));
            user.setRole(userRole);
            user.setEstado("ACTIVO");
            user.setPrimerLogin(true);
            user.setIdEmpresa(1); // Hardcoded default value

            UsuarioCliente usuarioCliente = new UsuarioCliente(user, savedCliente);
            user.setUsuarioCliente(usuarioCliente);

            userRepository.save(user);

            // Send credentials email
            String subject = "Bienvenido a Nuestro Servicio - Sus Credenciales";
            String body = "<html>"
                    + "<body>"
                    + "<h2>¡Hola " + nombres + ", bienvenido a nuestro servicio!</h2>"
                    + "<p>Su cuenta ha sido creada exitosamente. A continuación, encontrará sus credenciales para iniciar sesión:</p>"
                    + "<p><strong>Usuario:</strong> " + generatedUsername + "</p>"
                    + "<p><strong>Contraseña Temporal:</strong> " + tempPassword + "</p>"
                    + "<p>Por su seguridad, se le pedirá que cambie su contraseña después de su primer inicio de sesión.</p>"
                    + "<p>Gracias por registrarse.</p>"
                    + "</body>"
                    + "</html>";

            mailService.sendEmail(email, subject, body);

            return ResponseEntity.ok(new MessageResponse("Registro exitoso. Se han enviado las credenciales a su correo."));
        } catch (Exception e) {
            log.error("Registration failed due to an unexpected error: {}", e.getMessage(), e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(new MessageResponse("Error interno del servidor durante el registro."));
        }
    }

    @PostMapping("/change-password")
    @Transactional
    public ResponseEntity<?> changePassword(@Valid @RequestBody ChangePasswordRequest changePasswordRequest) {
        UserDetails userDetails = (UserDetails) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        User user = userRepository.findByUsername(userDetails.getUsername())
                .orElseThrow(() -> new RuntimeException("Error: Usuario no encontrado."));

        if (!encoder.matches(changePasswordRequest.getOldPassword(), user.getPassword())) {
            return ResponseEntity.badRequest().body(new MessageResponse("Error: Contraseña actual incorrecta."));
        }

        user.setPassword(encoder.encode(changePasswordRequest.getNewPassword()));
        user.setPrimerLogin(false);
        userRepository.save(user);

        return ResponseEntity.ok(new MessageResponse("Contraseña cambiada exitosamente."));
    }

    @PostMapping("/forgot-password")
    @Transactional
    public ResponseEntity<?> forgotPassword(@Valid @RequestBody ForgotPasswordRequest forgotPasswordRequest) {
        Optional<Cliente> clienteOpt = clienteRepository.findByCorreo(forgotPasswordRequest.getEmail());

        if (clienteOpt.isEmpty()) {
            // Don't reveal that the user doesn't exist.
            return ResponseEntity.ok(new MessageResponse("Si existe una cuenta con ese correo, se ha enviado un enlace para restablecer la contraseña."));
        }

        Cliente cliente = clienteOpt.get();
        Optional<UsuarioCliente> usuarioClienteOpt = usuarioClienteRepository.findByCliente(cliente);

        if (usuarioClienteOpt.isEmpty()) {
            // This case should ideally not happen if data is consistent
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(new MessageResponse("Error: No se encontró un usuario asociado a este cliente."));
        }

        User user = usuarioClienteOpt.get().getUser();
        if (user == null) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(new MessageResponse("Error: Inconsistencia de datos, el cliente no tiene un usuario."));
        }

        String token = UUID.randomUUID().toString();
        user.setResetPasswordToken(token);
        user.setResetPasswordTokenExpiry(LocalDateTime.now().plusHours(1)); // Token valid for 1 hour
        userRepository.save(user);

        String resetLink = "http://localhost:4200/reset-password?token=" + token;
        String subject = "Restablecimiento de Contraseña - SGIM";
        String body = "<html>"
                + "<body>"
                + "<h2>Hola " + cliente.getNombres() + ",</h2>"
                + "<p>Recibimos una solicitud para restablecer tu contraseña. Haz clic en el siguiente enlace para continuar:</p>"
                + "<p><a href=\"" + resetLink + "\">Restablecer Contraseña</a></p>"
                + "<p>Si no solicitaste esto, puedes ignorar este correo de forma segura.</p>"
                + "<p>El enlace expirará en 1 hora.</p>"
                + "</body>"
                + "</html>";

        mailService.sendEmail(cliente.getCorreo(), subject, body);

        return ResponseEntity.ok(new MessageResponse("Si existe una cuenta con ese correo, se ha enviado un enlace para restablecer la contraseña."));
    }

    @PostMapping("/reset-password")
    @Transactional
    public ResponseEntity<?> resetPassword(@Valid @RequestBody ResetPasswordRequest resetPasswordRequest) {
        Optional<User> userOpt = userRepository.findByResetPasswordToken(resetPasswordRequest.getToken());

        if (userOpt.isEmpty()) {
            return ResponseEntity.badRequest().body(new MessageResponse("Token de restablecimiento de contraseña inválido."));
        }

        User user = userOpt.get();

        if (user.getResetPasswordTokenExpiry() == null || user.getResetPasswordTokenExpiry().isBefore(LocalDateTime.now())) {
            return ResponseEntity.badRequest().body(new MessageResponse("El token de restablecimiento de contraseña ha expirado."));
        }

        user.setPassword(encoder.encode(resetPasswordRequest.getNewPassword()));
        user.setResetPasswordToken(null);
        user.setResetPasswordTokenExpiry(null);
        user.setPrimerLogin(false); // Ensure primerLogin is false after manual reset
        userRepository.save(user);

        return ResponseEntity.ok(new MessageResponse("Contraseña restablecida exitosamente."));
    }

    @GetMapping("/validate-reset-token")
    public ResponseEntity<?> validateResetToken(@RequestParam String token) {
        Optional<User> userOpt = userRepository.findByResetPasswordToken(token);

        if (userOpt.isEmpty()) {
            return ResponseEntity.badRequest().body(new MessageResponse("Token de restablecimiento de contraseña inválido."));
        }

        User user = userOpt.get();

        if (user.getResetPasswordTokenExpiry() == null || user.getResetPasswordTokenExpiry().isBefore(LocalDateTime.now())) {
            return ResponseEntity.badRequest().body(new MessageResponse("El token de restablecimiento de contraseña ha expirado."));
        }

        return ResponseEntity.ok(new MessageResponse("Token válido."));
    }

    private String getEmailForUser(User user) {
        UsuarioCliente usuarioCliente = usuarioClienteRepository.findById(user.getId()).orElse(null);
        if (usuarioCliente != null && usuarioCliente.getCliente() != null) {
            return usuarioCliente.getCliente().getCorreo();
        }
        // TODO: Add logic for Empleado if necessary
        return null;
    }

    private String generateTemporaryPassword(String cedula) {
        if (cedula == null || cedula.length() < 4) {
            cedula = String.valueOf(new Random().nextInt(10000));
        }
        Random random = new Random();
        int fourDigitNumber = 1000 + random.nextInt(9000);
        return cedula.substring(cedula.length() - 4) + "*" + fourDigitNumber;
    }
}

