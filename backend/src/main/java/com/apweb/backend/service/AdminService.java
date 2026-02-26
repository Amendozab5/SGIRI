package com.apweb.backend.service;

import com.apweb.backend.model.Role;
import com.apweb.backend.model.User;
import com.apweb.backend.payload.request.UserCreateRequest;
import com.apweb.backend.payload.request.UserUpdateRequest;
import com.apweb.backend.payload.response.UserAdminView;
import com.apweb.backend.repository.RoleRepository;
import com.apweb.backend.repository.UserRepository;
import com.apweb.backend.repository.PersonaRepository;
import com.apweb.backend.repository.CatalogoItemRepository;
import com.apweb.backend.model.CatalogoItem;
import com.apweb.backend.model.Persona;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Collections;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class AdminService {

        @Autowired
        private UserRepository userRepository;

        @Autowired
        private RoleRepository roleRepository; // Inject RoleRepository

        @Autowired
        private PasswordEncoder passwordEncoder; // Inject PasswordEncoder

        @Autowired
        private PersonaRepository personaRepository;

        @Autowired
        private CatalogoItemRepository catalogoItemRepository;

        @Transactional(readOnly = true)
        public List<UserAdminView> getAllUsersForAdmin(String roleName) {
                List<User> users;
                if (roleName != null && !roleName.isEmpty() && !roleName.equalsIgnoreCase("all")) {
                        String dbRoleName = roleName.startsWith("ROLE_") ? roleName.substring(5) : roleName;
                        Role role = roleRepository.findByCodigo(dbRoleName)
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

                user.setEstado(status);
                userRepository.save(user);
        }

        @Transactional
        public UserAdminView createUser(UserCreateRequest request) {
                if (userRepository.existsByUsername(request.getUsername())) {
                        throw new RuntimeException("Error: Username is already taken!");
                }

                User user = new User();
                user.setUsername(request.getUsername());
                user.setPassword(passwordEncoder.encode(request.getPassword()));

                CatalogoItem status = catalogoItemRepository.findFirstByCodigo("ACTIVO")
                                .orElseThrow(() -> new RuntimeException("Error: Default status ACTIVO not found."));
                user.setEstado(status);

                user.setPrimerLogin(true);
                user.setIdEmpresa(1); // TODO: Get idEmpresa from authenticated user context or request

                String createRoleCode = request.getRole() != null && request.getRole().startsWith("ROLE_")
                                ? request.getRole().substring(5)
                                : request.getRole();
                Role userRole = roleRepository.findByCodigo(createRoleCode)
                                .orElseThrow(() -> new RuntimeException("Error: Role is not found."));
                user.setRole(userRole);

                User savedUser = userRepository.save(user);
                return mapToUserAdminView(savedUser);
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
                                        "Error: El estado '" + request.getEstado()
                                                        + "' está deshabilitado en el catálogo.");
                }

                user.setEstado(status);

                String updateRoleCode = request.getRole() != null && request.getRole().startsWith("ROLE_")
                                ? request.getRole().substring(5)
                                : request.getRole();
                Role userRole = roleRepository.findByCodigo(updateRoleCode)
                                .orElseThrow(() -> new RuntimeException("Error: Role is not found."));
                user.setRole(userRole);

                User updatedUser = userRepository.save(user);
                return mapToUserAdminView(updatedUser);
        }

        @Transactional
        public void deleteUser(Integer userId) {
                User user = userRepository.findById(userId)
                                .orElseThrow(() -> new RuntimeException("Error: User not found with id " + userId));

                // Delete associated Persona (cascades to User if configured, or manual delete)
                Persona persona = user.getPersona();
                if (persona != null) {
                        personaRepository.delete(persona);
                }

                userRepository.delete(user);
        }

        private UserAdminView mapToUserAdminView(User user) {
                String email = "N/A";
                String fullName = "N/A";

                Persona persona = user.getPersona();
                if (persona != null) {
                        email = persona.getCorreo();
                        fullName = persona.getNombre() + " " + persona.getApellido();
                }

                List<String> roles = Collections.singletonList(user.getRole().getCodigo());

                return new UserAdminView(
                                user.getId(),
                                user.getUsername(),
                                fullName,
                                email,
                                roles,
                                user.getEstado() != null ? user.getEstado().getCodigo() : "N/A",
                                user.getFechaCreacion(),
                                user.getFechaActualizacion());
        }
}
