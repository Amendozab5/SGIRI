package com.apweb.backend.service;

import com.apweb.backend.model.Cliente;
import com.apweb.backend.model.Empleado;
import com.apweb.backend.model.User;
import com.apweb.backend.model.UsuarioCliente;
import com.apweb.backend.model.UsuarioEmpleado;
import com.apweb.backend.payload.response.UserProfileResponse;
import com.apweb.backend.repository.ClienteRepository;
import com.apweb.backend.repository.EmpleadoRepository;
import com.apweb.backend.repository.UserRepository;
import com.apweb.backend.repository.UsuarioClienteRepository;
import com.apweb.backend.repository.UsuarioEmpleadoRepository;
import com.apweb.backend.payload.request.UserProfileUpdateRequest; // New import
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.servlet.support.ServletUriComponentsBuilder;

import java.util.Collections;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class UserService {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private ClienteRepository clienteRepository;

    @Autowired
    private EmpleadoRepository empleadoRepository;
    
    @Autowired
    private UsuarioClienteRepository usuarioClienteRepository;

    @Autowired
    private UsuarioEmpleadoRepository usuarioEmpleadoRepository;

    @Autowired
    private FileStorageService fileStorageService;

    @Transactional(readOnly = true)
    public UserProfileResponse getUserProfile(String username) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("Error: Usuario no encontrado."));

        List<String> roles = user.getRole() != null ? Collections.singletonList(user.getRole().getCodigo()) : Collections.emptyList();
        
        // Try to find a Cliente associated with this user
        UsuarioCliente usuarioCliente = usuarioClienteRepository.findById(user.getId()).orElse(null);
        if (usuarioCliente != null) {
            Cliente cliente = usuarioCliente.getCliente();
            String profilePicUrl = cliente.getProfilePictureUrl() != null ? 
                createFileDownloadUri(cliente.getProfilePictureUrl()) : null;

            return new UserProfileResponse(
                user.getId(),
                user.getUsername(),
                cliente.getCorreo(),
                roles,
                cliente.getNombres(),
                cliente.getApellidos(),
                cliente.getCedula(),
                cliente.getCelular(), // Add celular here
                profilePicUrl
            );
        }

        // Try to find an Empleado associated with this user
        UsuarioEmpleado usuarioEmpleado = usuarioEmpleadoRepository.findById(user.getId()).orElse(null);
        if (usuarioEmpleado != null) {
            Empleado empleado = usuarioEmpleado.getEmpleado();
             String profilePicUrl = empleado.getProfilePictureUrl() != null ? 
                createFileDownloadUri(empleado.getProfilePictureUrl()) : null;

            return new UserProfileResponse(
                user.getId(),
                user.getUsername(),
                empleado.getCorreoPersonal() != null ? empleado.getCorreoPersonal() : empleado.getCorreoCorporativo(),
                roles,
                empleado.getNombre(),
                empleado.getApellido(),
                empleado.getCedula(),
                empleado.getCelular(), // Add celular here
                profilePicUrl
            );
        }

        // Fallback if user is neither Cliente nor Empleado
        return new UserProfileResponse(user.getId(), user.getUsername(), null, roles, "N/A", "N/A", "N/A", null, null);
    }

    @Transactional
    public UserProfileResponse updateUserProfile(String username, UserProfileUpdateRequest request) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("Error: Usuario no encontrado."));

        // Update Cliente profile
        UsuarioCliente usuarioCliente = usuarioClienteRepository.findById(user.getId()).orElse(null);
        if (usuarioCliente != null) {
            Cliente cliente = usuarioCliente.getCliente();
            cliente.setNombres(request.getNombre());
            cliente.setApellidos(request.getApellido());
            cliente.setCorreo(request.getEmail());
            cliente.setCelular(request.getCelular()); // Add celular here
            clienteRepository.save(cliente);
            return getUserProfile(username); // Return updated profile
        }

        // Update Empleado profile
        UsuarioEmpleado usuarioEmpleado = usuarioEmpleadoRepository.findById(user.getId()).orElse(null);
        if (usuarioEmpleado != null) {
            Empleado empleado = usuarioEmpleado.getEmpleado();
            empleado.setNombre(request.getNombre());
            empleado.setApellido(request.getApellido());
            // Prioritize updating personal email if available, otherwise corporate
            if (empleado.getCorreoPersonal() != null) {
                empleado.setCorreoPersonal(request.getEmail());
            } else {
                empleado.setCorreoCorporativo(request.getEmail());
            }
            empleado.setCelular(request.getCelular()); // Add celular here
            empleadoRepository.save(empleado);
            return getUserProfile(username); // Return updated profile
        }

        throw new RuntimeException("Error: Perfil de usuario (Cliente o Empleado) no encontrado para actualizar.");
    }


    @Transactional
    public String updateProfilePicture(String username, MultipartFile file) {
        User user = userRepository.findByUsername(username)
            .orElseThrow(() -> new RuntimeException("Error: Usuario no encontrado."));

        String fileName = fileStorageService.save(file, username);
        String fileDownloadUri = createFileDownloadUri(fileName);

        // Try to find and update a Cliente
        UsuarioCliente usuarioCliente = usuarioClienteRepository.findById(user.getId()).orElse(null);
        if (usuarioCliente != null) {
            Cliente cliente = usuarioCliente.getCliente();
            cliente.setProfilePictureUrl(fileName); // Store just the file name
            clienteRepository.save(cliente);
            return fileDownloadUri;
        }

        // Try to find and update an Empleado
        UsuarioEmpleado usuarioEmpleado = usuarioEmpleadoRepository.findById(user.getId()).orElse(null);
        if (usuarioEmpleado != null) {
            Empleado empleado = usuarioEmpleado.getEmpleado();
            empleado.setProfilePictureUrl(fileName); // Store just the file name
            empleadoRepository.save(empleado);
            return fileDownloadUri;
        }
        
        throw new RuntimeException("Error: Perfil de usuario (Cliente o Empleado) no encontrado para asociar la imagen.");
    }

    private String createFileDownloadUri(String fileName) {
        return ServletUriComponentsBuilder.fromCurrentContextPath()
                .path("/uploads/")
                .path(fileName)
                .toUriString();
    }
}