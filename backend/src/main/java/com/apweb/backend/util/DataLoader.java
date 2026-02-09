package com.apweb.backend.util;

import com.apweb.backend.model.Canton;
import com.apweb.backend.model.Ciudad;
import com.apweb.backend.model.Empresa;
import com.apweb.backend.model.Pais;
import com.apweb.backend.model.Role;
import com.apweb.backend.model.User;
import com.apweb.backend.repository.CantonRepository;
import com.apweb.backend.repository.CiudadRepository;
import com.apweb.backend.repository.EmpresaRepository;
import com.apweb.backend.repository.PaisRepository;
import com.apweb.backend.repository.RoleRepository;
import com.apweb.backend.repository.UserRepository;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.Map;

@Component
public class DataLoader implements CommandLineRunner {

    private final UserRepository userRepository;
    private final RoleRepository roleRepository;
    private final PasswordEncoder passwordEncoder;
    private final PaisRepository paisRepository;
    private final CiudadRepository ciudadRepository;
    private final CantonRepository cantonRepository;
    private final EmpresaRepository empresaRepository;

    public DataLoader(UserRepository userRepository, RoleRepository roleRepository, PasswordEncoder passwordEncoder,
                      PaisRepository paisRepository, CiudadRepository ciudadRepository, CantonRepository cantonRepository,
                      EmpresaRepository empresaRepository) {
        this.userRepository = userRepository;
        this.roleRepository = roleRepository;
        this.passwordEncoder = passwordEncoder;
        this.paisRepository = paisRepository;
        this.ciudadRepository = ciudadRepository;
        this.cantonRepository = cantonRepository;
        this.empresaRepository = empresaRepository;
    }

    @Override
    @Transactional
    public void run(String... args) throws Exception {
        createRoles();
        createDefaultEmpresa();
        createSystemUsers();
        createGeographyData();
    }

    private void createRoles() {
        Map<String, String> roles = Map.of(
            "ROLE_ADMIN", "Administrator role with full access.",
            "ROLE_TECHNICIAN", "Technician role for handling incidents.",
            "ROLE_USER", "Standard user role for clients."
        );
        roles.forEach((roleCode, roleDescription) -> {
            if (roleRepository.findByCodigo(roleCode).isEmpty()) {
                Role newRole = new Role();
                newRole.setCodigo(roleCode);
                newRole.setDescripcion(roleDescription);
                roleRepository.save(newRole);
                System.out.println(">>> Created role: " + roleCode);
            }
        });
    }

    private void createDefaultEmpresa() {
        if (empresaRepository.count() == 0) {
            Empresa empresa = new Empresa();
            empresa.setNombreComercial("Empresa Por Defecto");
            empresa.setRazonSocial("Empresa Por Defecto S.A.");
            empresa.setRuc("0000000000000");
            empresa.setTipoEmpresa("MATRIZ");
            empresa.setEstado("ACTIVO");
            empresa.setFechaCreacion(LocalDateTime.now());
            empresaRepository.save(empresa);
            System.out.println(">>> Created default empresa");
        }
    }

    private void createSystemUsers() {
        Empresa defaultEmpresa = empresaRepository.findAll().get(0);

        if (userRepository.findByUsername("admin").isEmpty()) {
            Role adminRole = roleRepository.findByCodigo("ROLE_ADMIN")
                    .orElseThrow(() -> new RuntimeException("CRITICAL: ROLE_ADMIN not found in database."));
            User adminUser = User.builder()
                    .username("admin")
                    .password(passwordEncoder.encode("password"))
                    .role(adminRole)
                    .estado("ACTIVO")
                    .primerLogin(false)
                    .idEmpresa(defaultEmpresa.getId())
                    .build();
            userRepository.save(adminUser);
            System.out.println(">>> Admin user created: admin/password");
        }

        if (userRepository.findByUsername("tech").isEmpty()) {
            Role techRole = roleRepository.findByCodigo("ROLE_TECHNICIAN")
                    .orElseThrow(() -> new RuntimeException("CRITICAL: ROLE_TECHNICIAN not found in database."));
            User techUser = User.builder()
                    .username("tech")
                    .password(passwordEncoder.encode("password"))
                    .role(techRole)
                    .estado("ACTIVO")
                    .primerLogin(false)
                    .idEmpresa(defaultEmpresa.getId())
                    .build();
            userRepository.save(techUser);
            System.out.println(">>> Technician user created: tech/password");
        }

        if (userRepository.findByUsername("user").isEmpty()) {
            Role userRole = roleRepository.findByCodigo("ROLE_USER")
                    .orElseThrow(() -> new RuntimeException("CRITICAL: ROLE_USER not found in database."));
            User regularUser = User.builder()
                    .username("user")
                    .password(passwordEncoder.encode("password"))
                    .role(userRole)
                    .estado("ACTIVO")
                    .primerLogin(false)
                    .idEmpresa(defaultEmpresa.getId())
                    .build();
            userRepository.save(regularUser);
            System.out.println(">>> Regular user created: user/password");
        }
    }

    private void createGeographyData() {
        if (paisRepository.count() > 0) {
            return; // Data already exists
        }
        
        System.out.println(">>> Creating geography data...");

        Pais ecuador = new Pais();
        ecuador.setNombre("Ecuador");
        Pais savedEcuador = paisRepository.save(ecuador);

        // Guayas
        Ciudad guayaquil = new Ciudad();
        guayaquil.setNombre("Guayaquil");
        guayaquil.setPais(savedEcuador);
        Ciudad savedGuayaquil = ciudadRepository.save(guayaquil);

        Canton gyeCanton = new Canton();
        gyeCanton.setNombre("Guayaquil");
        gyeCanton.setCiudad(savedGuayaquil);
        cantonRepository.save(gyeCanton); // This will have ID 1

        Canton dauenCanton = new Canton();
        dauenCanton.setNombre("Daule");
        dauenCanton.setCiudad(savedGuayaquil);
        cantonRepository.save(dauenCanton);

        // Pichincha
        Ciudad quito = new Ciudad();
        quito.setNombre("Quito");
        quito.setPais(savedEcuador);
        Ciudad savedQuito = ciudadRepository.save(quito);

        Canton quitoCanton = new Canton();
        quitoCanton.setNombre("Quito");
        quitoCanton.setCiudad(savedQuito);
        cantonRepository.save(quitoCanton);

        System.out.println(">>> Geography data created.");
    }
}