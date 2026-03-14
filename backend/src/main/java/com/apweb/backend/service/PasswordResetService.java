package com.apweb.backend.service;

import com.apweb.backend.model.User;
import com.apweb.backend.repository.UserRepository;
import com.apweb.backend.security.jwt.JwtUtils;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Optional;

@Service
public class PasswordResetService {

    private final UserRepository userRepository;
    private final MailService mailService;
    private final PasswordEncoder passwordEncoder;
    private final JwtUtils jwtUtils;

    public PasswordResetService(UserRepository userRepository,
                                MailService mailService,
                                PasswordEncoder passwordEncoder,
                                JwtUtils jwtUtils) {
        this.userRepository = userRepository;
        this.mailService = mailService;
        this.passwordEncoder = passwordEncoder;
        this.jwtUtils = jwtUtils;
    }

    @Transactional
    public void createPasswordResetTokenForUser(String email) {
        User user = userRepository.findByPersona_Correo(email)
                .orElseThrow(() -> new RuntimeException("No se encontró un usuario con ese correo electrónico."));

        // Generamos un token JWT que incluye el hash actual de la contraseña.
        // Si la contraseña cambia, el token se invalida automáticamente.
        String token = jwtUtils.generatePasswordResetToken(user.getUsername(), user.getPassword());

        String resetLink = "http://localhost:4200/reset-password?token=" + token;
        String emailContent = mailService.getPasswordResetEmailTemplate(resetLink);
        
        mailService.sendEmail(email, "Recuperación de Contraseña - SGIM", emailContent);
    }

    public boolean validatePasswordResetToken(String token) {
        try {
            String username = jwtUtils.getUserNameFromJwtToken(token);
            Optional<User> user = userRepository.findByUsername(username);
            return user.isPresent() && jwtUtils.validatePasswordResetToken(token, user.get().getPassword());
        } catch (Exception e) {
            return false;
        }
    }

    @Transactional
    public void changeUserPassword(String token, String newPassword) {
        String username = jwtUtils.getUserNameFromJwtToken(token);
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("Token de recuperación inválido o expirado."));

        if (!jwtUtils.validatePasswordResetToken(token, user.getPassword())) {
            throw new RuntimeException("El token ya no es válido o ya fue utilizado.");
        }

        user.setPassword(passwordEncoder.encode(newPassword));
        userRepository.save(user);
    }
}
