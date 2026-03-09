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

        // --- Catálogos para el Flujo del Técnico ---
        createCatFlow("IMPLEMENTOS_TECNICOS", "Catálogo de implementos o herramientas no inventariadas.",
                java.util.List.of(
                        "NO_APLICA", "SIN_MATERIAL", "Cable HDMI", "Cable de red", "Router", "Switch", "Adaptador",
                        "Fuente de poder", "Disco duro", "Memoria RAM", "Patch cord", "Convertidor USB", "Antena WiFi",
                        "Laptop de prueba"));

        createCatFlow("PROBLEMAS_TECNICOS", "Catálogo de problemas encontrados.", java.util.List.of(
                "NO_APLICA", "Cable dañado", "Configuración incorrecta", "Hardware defectuoso", "Virus detectado",
                "Sistema desactualizado", "Señal débil WiFi", "Puerto quemado", "Falta de drivers",
                "Sobrecalentamiento",
                "Error de software", "Saturación de red"));

        createCatFlow("SOLUCIONES_TECNICAS", "Catálogo de soluciones aplicadas.", java.util.List.of(
                "NO_APLICA", "Reemplazo de cable", "Reconfiguración del sistema", "Instalación de drivers",
                "Eliminación de virus", "Actualización del sistema", "Cambio de hardware", "Reseteo de router",
                "Optimización de red", "Reinstalación de software", "Cambio de configuración IP",
                "Limpieza de equipo"));

        createCatFlow("PRUEBAS_TECNICAS", "Catálogo de pruebas realizadas.", java.util.List.of(
                "NO_APLICA", "Reinicio del sistema", "Prueba de conexión", "Test de velocidad", "Test de hardware",
                "Prueba de ping", "Verificación de puertos", "Monitoreo de red", "Prueba de aplicación",
                "Test de carga"));

        createCatFlow("MOTIVOS_NO_RESOLUCION_TECNICA", "Catálogo de motivos por los que no se resolvió un ticket.",
                java.util.List.of(
                        "Falta de repuestos", "Problema mayor identificado", "Requiere especialista externo",
                        "Cliente no disponible",
                        "Problema externo al ISP", "Requiere visita presencial adicional", "Espera de autorización"));
    }

    private void createCatFlow(String nombreCat, String descripcion, java.util.List<String> items) {
        Optional<Catalogo> catOpt = catalogoRepository.findByNombre(nombreCat);
        Catalogo cat;
        if (catOpt.isEmpty()) {
            cat = new Catalogo();
            cat.setNombre(nombreCat);
            cat.setDescripcion(descripcion);
            cat.setActivo(true);
            cat = catalogoRepository.save(cat);
            System.out.println("DataLoader: Creado catálogo " + nombreCat);
        } else {
            cat = catOpt.get();
        }

        int orden = 1;
        for (String itemStr : items) {
            String codigo = itemStr.toUpperCase().replace(" ", "_").replace("Ñ", "N").replace("Á", "A")
                    .replace("É", "E").replace("Í", "I").replace("Ó", "O").replace("Ú", "U");
            createItemIfMissing(cat, codigo, itemStr, orden++);
        }
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