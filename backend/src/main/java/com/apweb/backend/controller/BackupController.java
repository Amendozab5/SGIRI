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

import java.io.InputStream;
import java.util.Map;

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

    /**
     * Genera un backup completo de la BD y lo retorna como descarga directa al navegador.
     *
     * <p>HTTP 200 + archivo → backup generado correctamente.</p>
     * <p>HTTP 409              → ya hay un backup en curso.</p>
     * <p>HTTP 503              → timeout al ejecutar pg_dump.</p>
     * <p>HTTP 500              → error de proceso u otro fallo interno.</p>
     */
    @PostMapping("/generar")
    @PreAuthorize("hasRole('ADMIN_MASTER')")
    public ResponseEntity<?> generarBackup() {
        log.info("[BACKUP] Solicitud de backup recibida.");

        try {
            BackupService.BackupResult resultado = backupService.ejecutarBackup();

            InputStream stream = backupService.abrirYBorrarTrasLeer(resultado.archivo);

            HttpHeaders headers = new HttpHeaders();
            headers.add(HttpHeaders.CONTENT_DISPOSITION,
                    "attachment; filename=\"" + resultado.nombreArchivo + "\"");
            headers.add(HttpHeaders.CONTENT_LENGTH, String.valueOf(resultado.tamanoBytes));

            return ResponseEntity
                    .ok()
                    .headers(headers)
                    .contentType(MediaType.APPLICATION_OCTET_STREAM)
                    .body(new InputStreamResource(stream));

        } catch (BackupException e) {
            return switch (e.getTipo()) {
                case CONCURRENCIA -> {
                    log.warn("[BACKUP] Solicitud rechazada — backup ya en curso.");
                    yield ResponseEntity
                            .status(HttpStatus.CONFLICT)
                            .body(Map.of("error", e.getMessage()));
                }
                case TIMEOUT -> {
                    log.error("[BACKUP] Timeout al generar el backup.");
                    yield ResponseEntity
                            .status(HttpStatus.SERVICE_UNAVAILABLE)
                            .body(Map.of("error", e.getMessage()));
                }
                default -> {
                    log.error("[BACKUP] Error al generar el backup: {}", e.getMessage());
                    yield ResponseEntity
                            .status(HttpStatus.INTERNAL_SERVER_ERROR)
                            .body(Map.of("error", e.getMessage()));
                }
            };
        } catch (Exception e) {
            log.error("[BACKUP] Error inesperado al preparar la descarga: {}", e.getMessage(), e);
            return ResponseEntity
                    .status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", "Error interno al preparar el archivo de backup."));
        }
    }
}
