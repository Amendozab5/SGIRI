package com.apweb.backend.util;

import com.apweb.backend.model.Role;
import com.apweb.backend.repository.RoleRepository;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.util.Map;

@Component
public class DataLoader implements CommandLineRunner {

    private final RoleRepository roleRepository;

    public DataLoader(RoleRepository roleRepository) {
        this.roleRepository = roleRepository;
    }

    @Override
    @Transactional
    public void run(String... args) throws Exception {
        // El DataLoader se mantiene minimalista para no entrar en conflicto con scripts
        // SQL externos.
        // Solo asegura que existan los roles básicos si la DB está vacía.
        createRoles();
    }

    private void createRoles() {
        Map<String, String> roles = Map.of(
                "ADMIN_MASTER", "Administrador general del sistema",
                "TECNICO", "Empleado técnico",
                "CLIENTE", "Usuario cliente del sistema");
        roles.forEach((roleCode, roleDescription) -> {
            if (roleRepository.findByCodigo(roleCode).isEmpty()) {
                Role newRole = new Role();
                newRole.setCodigo(roleCode);
                newRole.setDescripcion(roleDescription);
                roleRepository.save(newRole);
            }
        });
    }
}