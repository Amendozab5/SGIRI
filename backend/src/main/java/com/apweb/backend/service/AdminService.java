package com.apweb.backend.service;

import com.apweb.backend.model.Role;
import com.apweb.backend.model.User;
import com.apweb.backend.model.Cliente; // Added import
import com.apweb.backend.model.UsuarioCliente; // Added import
import com.apweb.backend.payload.request.UserCreateRequest;
import com.apweb.backend.payload.request.UserUpdateRequest;
import com.apweb.backend.payload.response.UserAdminView;
import com.apweb.backend.repository.RoleRepository;
import com.apweb.backend.repository.UserRepository;
import com.apweb.backend.repository.ClienteRepository; // Added import
import com.apweb.backend.repository.UsuarioClienteRepository; // Added import
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
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
    private ClienteRepository clienteRepository; // New injection

    @Autowired
    private UsuarioClienteRepository usuarioClienteRepository; // New injection

    @Transactional(readOnly = true)
    public List<UserAdminView> getAllUsersForAdmin(String roleName) {
        List<User> users;
        if (roleName != null && !roleName.isEmpty() && !roleName.equalsIgnoreCase("all")) {
            Role role = roleRepository.findByCodigo(roleName)
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
    public void toggleUserStatus(Integer userId, String newStatus) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("Error: User not found with id " + userId));
        user.setEstado(newStatus);
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
        user.setEstado("ACTIVO"); // Default status for new user
        user.setPrimerLogin(true); // New users should have to change password
        user.setIdEmpresa(1); // TODO: Get idEmpresa from authenticated user context or request

        Role userRole = roleRepository.findByCodigo(request.getRole())
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
        user.setEstado(request.getEstado());

        Role userRole = roleRepository.findByCodigo(request.getRole())
                .orElseThrow(() -> new RuntimeException("Error: Role is not found."));
        user.setRole(userRole);

        User updatedUser = userRepository.save(user);
        return mapToUserAdminView(updatedUser);
    }

    @Transactional
    public void deleteUser(Integer userId) {
        User user = userRepository.findByIdWithUsuarioCliente(userId)
                .orElseThrow(() -> new RuntimeException("Error: User not found with id " + userId));

        // Check if the user is associated with a client
        if (user.getUsuarioCliente() != null) {
            UsuarioCliente usuarioCliente = user.getUsuarioCliente();
            Cliente cliente = usuarioCliente.getCliente();

            // Delete the UsuarioCliente association
            usuarioClienteRepository.delete(usuarioCliente);

            // Delete the Client
            if (cliente != null) {
                clienteRepository.delete(cliente);
            }
        }
        // TODO: Add similar logic for UsuarioEmpleado if applicable

        // Finally, delete the User
        userRepository.delete(user);
    }

    private UserAdminView mapToUserAdminView(User user) {
        String email = "N/A";
        String fullName = "N/A";

        if (user.getUsuarioCliente() != null && user.getUsuarioCliente().getCliente() != null) {
            email = user.getUsuarioCliente().getCliente().getCorreo();
            fullName = user.getUsuarioCliente().getCliente().getNombres() + " " + user.getUsuarioCliente().getCliente().getApellidos();
        } else if (user.getUsuarioEmpleado() != null && user.getUsuarioEmpleado().getEmpleado() != null) {
            email = user.getUsuarioEmpleado().getEmpleado().getCorreoCorporativo(); // Or correoPersonal
            fullName = user.getUsuarioEmpleado().getEmpleado().getNombre() + " " + user.getUsuarioEmpleado().getEmpleado().getApellido();
        }

        List<String> roles = Collections.singletonList(user.getRole().getCodigo());

        return new UserAdminView(
                user.getId(),
                user.getUsername(),
                fullName,
                email,
                roles,
                user.getEstado(),
                user.getLastLogin(),
                user.getFechaCreacion()
        );
    }
}
