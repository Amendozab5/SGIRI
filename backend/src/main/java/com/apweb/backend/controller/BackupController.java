package com.apweb.backend.controller;

import com.apweb.backend.service.BackupService;
import com.apweb.backend.service.BackupService.BackupException;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.core.io.InputStreamResource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.InputStream;
import java.util.Map;
import com.apweb.backend.model.ConfiguracionBackup;
import com.apweb.backend.model.RegistroBackup;
import java.io.IOException;
import java.util.List;

/**
 * Endpoint para generación de backup completo de la base de datos.
 * Acceso restringido exclusivamente a ADMIN_MASTER.
 */
@RestController
@RequestMapping("/api/admin/backup")
@RequiredArgsConstructor
public class BackupController {

    private static final Logger log = LoggerFactory.getLogger(BackupController.class);

    private final BackupService backupService;

    @PostMapping("/generar")
    @PreAuthorize("hasRole('ADMIN_MASTER')")
    public ResponseEntity<?> generarBackup(
            @RequestParam(defaultValue = "DATABASE") String type,
            @RequestParam(defaultValue = "CUSTOM") String format) {

        log.info("[BACKUP] Solicitud recibida: Tipo={}, Formato={}", type, format);

        try {
            BackupService.BackupType   bType   = BackupService.BackupType.valueOf(type.toUpperCase());
            BackupService.BackupFormat bFormat = BackupService.BackupFormat.valueOf(format.toUpperCase());

            BackupService.BackupResult resultado = backupService.ejecutarBackup(bType, bFormat);

            InputStream stream = backupService.abrirYBorrarTrasLeer(resultado.archivo);

            HttpHeaders headers = new HttpHeaders();
            headers.add(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + resultado.nombreArchivo + "\"");
            headers.add(HttpHeaders.CONTENT_LENGTH, String.valueOf(resultado.tamanoBytes));

            return ResponseEntity.ok()
                    .headers(headers)
                    .contentType(MediaType.APPLICATION_OCTET_STREAM)
                    .body(new InputStreamResource(stream));

        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("error", "Parámetros inválidos: " + e.getMessage()));
        } catch (BackupException e) {
            log.error("[BACKUP] Error controlado: {}", e.getMessage());
            HttpStatus status = switch (e.getTipo()) {
                case CONCURRENCIA -> HttpStatus.CONFLICT;
                case TIMEOUT      -> HttpStatus.SERVICE_UNAVAILABLE;
                default           -> HttpStatus.INTERNAL_SERVER_ERROR;
            };
            return ResponseEntity.status(status).body(Map.of("error", e.getMessage()));
        } catch (Exception e) {
            log.error("[BACKUP] Error inesperado: {}", e.getMessage(), e);
            return ResponseEntity.internalServerError().body(Map.of("error", "Error interno al preparar descarga."));
        }
    }

    @PostMapping("/restaurar")
    @PreAuthorize("hasRole('ADMIN_MASTER')")
    public ResponseEntity<?> restaurarBackup(
            @RequestParam("file") MultipartFile file,
            @RequestParam(defaultValue = "CUSTOM") String format) {

        log.info("[RESTORE] Solicitud de restauración: Archivo={}, Formato={}", file.getOriginalFilename(), format);

        try {
            BackupService.BackupFormat bFormat = BackupService.BackupFormat.valueOf(format.toUpperCase());
            backupService.restaurarBackup(file, bFormat);

            return ResponseEntity.ok(Map.of("message", "Restauración completada con éxito sobre la base de datos de Sandbox."));

        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("error", "Formato inválido: " + format));
        } catch (BackupException e) {
            log.error("[RESTORE] Error controlado: {}", e.getMessage());
            HttpStatus status = switch (e.getTipo()) {
                case CONCURRENCIA -> HttpStatus.CONFLICT;
                case TIMEOUT      -> HttpStatus.SERVICE_UNAVAILABLE;
                default           -> HttpStatus.INTERNAL_SERVER_ERROR;
            };
            return ResponseEntity.status(status).body(Map.of("error", e.getMessage()));
        } catch (Exception e) {
            log.error("[RESTORE] Error inesperado en restauración: {}", e.getMessage(), e);
            return ResponseEntity.internalServerError().body(Map.of("error", "Error interno durante la restauración."));
        }
    }

    @GetMapping("/config")
    @PreAuthorize("hasRole('ADMIN_MASTER')")
    public ResponseEntity<ConfiguracionBackup> obtenerConfiguracion() {
        return ResponseEntity.ok(backupService.getConfiguracionActual());
    }

    @PostMapping("/config")
    @PreAuthorize("hasRole('ADMIN_MASTER')")
    public ResponseEntity<ConfiguracionBackup> guardarConfiguracion(@RequestBody ConfiguracionBackup config) {
        log.info("[BACKUP] Actualizando configuración de backups auto");
        return ResponseEntity.ok(backupService.guardarConfiguracion(config));
    }

    @GetMapping("/historial")
    @PreAuthorize("hasRole('ADMIN_MASTER')")
    public ResponseEntity<List<RegistroBackup>> obtenerHistorial() {
        return ResponseEntity.ok(backupService.listarHistorial());
    }

    @PostMapping("/ejecutar-periodico")
    @PreAuthorize("hasRole('ADMIN_MASTER')")
    public ResponseEntity<?> ejecutarBackupManualCompleto() {
        log.info("[BACKUP] Ejecución manual de flujo completo (Cloud + ZIP)");
        try {
            RegistroBackup registro = backupService.ejecutarBackupCompleto(
                    BackupService.BackupType.DATABASE, 
                    BackupService.BackupFormat.CUSTOM, 
                    true
            );
            return ResponseEntity.ok(registro);
        } catch (BackupException e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(Map.of("error", e.getMessage()));
        }
    }

    @DeleteMapping("/local/{filename}")
    @PreAuthorize("hasRole('ADMIN_MASTER')")
    public ResponseEntity<?> eliminarBackupLocal(@PathVariable String filename) {
        try {
            backupService.eliminarBackupLocalDisco(filename);
            return ResponseEntity.ok(Map.of("message", "Archivo eliminado del servidor exitosamente."));
        } catch (IOException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(Map.of("error", e.getMessage()));
        }
    }
}
