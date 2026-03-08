package com.apweb.backend.service;

import com.apweb.backend.model.Persona;
import com.apweb.backend.model.User;
import com.apweb.backend.payload.response.UserProfileResponse;
import com.apweb.backend.payload.request.UserProfileUpdateRequest;
import com.apweb.backend.repository.UserRepository;
import com.apweb.backend.repository.PersonaRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import com.apweb.backend.util.AuditAccion;
import com.apweb.backend.util.AuditModulo;
import org.springframework.security.crypto.password.PasswordEncoder;

@Service
public class UserService {

        @Autowired
        private UserRepository userRepository;

        @Autowired
        private DocumentService documentService;
        @Autowired
        private PersonaRepository personaRepository;

        @Autowired
        private PasswordEncoder encoder;

        @Autowired
        private AuditService auditService;

        @Transactional(readOnly = true)
        public UserProfileResponse getUserProfile(String username) {
                User user = userRepository.findByUsername(username)
                                .orElseThrow(() -> new RuntimeException("Error: Usuario no encontrado."));

                Persona persona = user.getPersona();
                List<String> roles = user.getRole() != null
                                ? Collections.singletonList("ROLE_" + user.getRole().getCodigo())
                                : Collections.emptyList();

                if (persona != null) {
                        return new UserProfileResponse(
                                        user.getId(),
                                        user.getUsername(),
                                        persona.getCorreo(),
                                        roles,
                                        persona.getNombre(),
                                        persona.getApellido(),
                                        persona.getCedula(),
                                        persona.getCelular(),
                                        documentService.getProfilePictureFilename(username),
                                        user.getIdEmpresa());
                }

                return new UserProfileResponse(user.getId(), user.getUsername(), null, roles, "N/A", "N/A", "N/A",
                                null, null, user.getIdEmpresa());
        }

        @Transactional
        public UserProfileResponse updateUserProfile(String username, UserProfileUpdateRequest request) {
                User user = userRepository.findByUsername(username)
                                .orElseThrow(() -> new RuntimeException("Error: Usuario no encontrado."));

                Persona persona = user.getPersona();
                if (persona == null) {
                        throw new RuntimeException("Error: No se encontró información personal para actualizar.");
                }

                persona.setNombre(request.getNombre());
                persona.setApellido(request.getApellido());
                persona.setCorreo(request.getEmail());
                persona.setCelular(request.getCelular());
                personaRepository.save(persona);

                // ── AUDITORÍA: Autogestión de Perfil ─────────────────────────────────
                auditService.registrarEventoContextual(
                        AuditModulo.PERFIL,
                        "usuarios", "persona",
                        persona.getIdPersona(),
                        AuditAccion.UPDATE,
                        "Autogestión de datos de perfil por el usuario",
                        null,
                        Map.of(
                            "nombre", persona.getNombre(),
                            "apellido", persona.getApellido(),
                            "correo", persona.getCorreo()
                        )
                );
                // ─────────────────────────────────────────────────────────────────────

                return getUserProfile(username);
        }

        @Transactional
        public void changePassword(User user, String oldPassword, String newPassword) {
                if (!encoder.matches(oldPassword, user.getPassword())) {
                        throw new RuntimeException("Error: Contraseña actual incorrecta.");
                }

                user.setPassword(encoder.encode(newPassword));
                user.setPrimerLogin(false);
                userRepository.save(user);

                // ── AUDITORÍA: Cambio de contraseña ──────────────────────────────────
                // En cumplimiento con las reglas de seguridad, NUNCA expone el hash ni el texto plano.
                // Se usa el string semánticamente seguro de confirmación del evento.
                auditService.registrarEvento(
                                AuditModulo.AUTH,
                                "usuarios", "usuario",
                                user.getId(),
                                AuditAccion.CAMBIO_PASSWORD,
                                "El usuario ha cambiado exitosamente su contraseña",
                                null,
                                Map.of("credencial_actualizada", true),
                                user.getId());
                // ────────────────────────────────────────────────────────────────────
        }

}