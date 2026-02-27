package com.apweb.backend.util;

import com.apweb.backend.model.Role;
import com.apweb.backend.model.Catalogo;
import com.apweb.backend.model.CatalogoItem;
import com.apweb.backend.repository.RoleRepository;
import com.apweb.backend.repository.CatalogoRepository;
import com.apweb.backend.repository.CatalogoItemRepository;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;
import org.springframework.beans.factory.annotation.Autowired;

import java.util.Map;
import java.util.Optional;

@Component
public class DataLoader implements CommandLineRunner {

    @Autowired
    private RoleRepository roleRepository;

    @Autowired
    private CatalogoRepository catalogoRepository;

    @Autowired
    private CatalogoItemRepository catalogoItemRepository;

    @Override
    public void run(String... args) throws Exception {
        System.out.println("DataLoader: Iniciando carga de datos...");
        try {
            createRoles();
            createCatalogos();
        } catch (Exception e) {
            System.err.println("DataLoader: Error crítico: " + e.getMessage());
        }
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

    private void createCatalogos() {
        String catNombre = "ESTADOS_GENERALES";
        Optional<Catalogo> catOpt = catalogoRepository.findByNombre(catNombre);

        Catalogo cat;
        if (catOpt.isEmpty()) {
            cat = new Catalogo();
            cat.setNombre(catNombre);
            cat.setDescripcion("Estados generales para empresas, sucursales y otros.");
            cat.setActivo(true);
            cat = catalogoRepository.save(cat);
            System.out.println("DataLoader: Creado catálogo " + catNombre);
        } else {
            cat = catOpt.get();
        }

        // Intentamos crear los items. Si el ACTIVO falta, es prioridad.
        createItemIfMissing(cat, "ACTIVO", "Activo", 1);
        createItemIfMissing(cat, "INACTIVO", "Inactivo", 2);
        createItemIfMissing(cat, "PENDIENTE", "Pendiente / En Espera", 3);
    }

    private void createItemIfMissing(Catalogo cat, String codigo, String nombre, int orden) {
        if (catalogoItemRepository.findByCatalogo_NombreAndCodigo(cat.getNombre(), codigo).isEmpty()) {
            boolean saved = false;
            int attempts = 0;
            // Hack para saltar errores de secuencia duplicada (PK violation)
            while (!saved && attempts < 50) {
                try {
                    attempts++;
                    CatalogoItem item = new CatalogoItem();
                    item.setCatalogo(cat);
                    item.setCodigo(codigo);
                    item.setNombre(nombre);
                    item.setOrden(orden);
                    item.setActivo(true);
                    catalogoItemRepository.save(item);
                    saved = true;
                    System.out.println("DataLoader: Creado item " + codigo + " en intento " + attempts);
                } catch (org.springframework.dao.DataIntegrityViolationException e) {
                    // Si es error de PK, intentamos de nuevo para que la secuencia avance
                    if (e.getMessage().contains("llave duplicada") || e.getMessage().contains("duplicate key")) {
                        continue;
                    } else {
                        System.err.println("DataLoader: Error de integridad para " + codigo + ": " + e.getMessage());
                        break;
                    }
                } catch (Exception e) {
                    System.err.println("DataLoader: Error inesperado para " + codigo + ": " + e.getMessage());
                    break;
                }
            }
        }
    }
}