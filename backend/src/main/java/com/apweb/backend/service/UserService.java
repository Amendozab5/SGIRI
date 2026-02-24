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

@Service
public class UserService {

        @Autowired
        private UserRepository userRepository;

        @Autowired
        private DocumentService documentService;
        @Autowired
        private PersonaRepository personaRepository;

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

                return getUserProfile(username);
        }

}