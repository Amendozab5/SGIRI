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
    private final PersonaRepository personaRepository;
    private final CatalogoItemRepository catalogoItemRepository;

    public AuthController(AuthenticationManager authenticationManager,
            UserRepository userRepository,
            RoleRepository roleRepository,
            PasswordEncoder encoder,
            JwtUtils jwtUtils,
            MailService mailService,
            ClienteRepository clienteRepository,
            PersonaRepository personaRepository,
            CatalogoItemRepository catalogoItemRepository) {
        this.authenticationManager = authenticationManager;
        this.userRepository = userRepository;
        this.roleRepository = roleRepository;
        this.encoder = encoder;
        this.jwtUtils = jwtUtils;
        this.mailService = mailService;
        this.clienteRepository = clienteRepository;
        this.personaRepository = personaRepository;
        this.catalogoItemRepository = catalogoItemRepository;
    }
