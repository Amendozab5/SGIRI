package com.apweb.backend.controller;

import com.apweb.backend.dto.DocumentoEmpleadoDTO;
import com.apweb.backend.model.TipoDocumento;
import com.apweb.backend.service.DocumentService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/documents")
public class DocumentController {

    private final DocumentService documentService;

    public DocumentController(DocumentService documentService) {
        this.documentService = documentService;
    }

    // ─── Tipos de documento (para dropdowns del formulario de subida) ─────────

    /**
     * Devuelve todos los tipos de documento disponibles (excluye FOTO).
     * Usado por el módulo de Empleados para poblar el selector de tipo de
     * documento.
     */
    @GetMapping("/tipos-documento")
    @PreAuthorize("hasRole('ADMIN_MASTER') or hasRole('ADMIN_TECNICOS') or hasRole('ADMIN_CONTRATOS')")
    public ResponseEntity<List<TipoDocumento>> getTiposDocumento() {
        return ResponseEntity.ok(documentService.getTiposDocumento());
    }

    @PostMapping("/upload-photo")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<Map<String, String>> uploadPhoto(@RequestParam(name = "file") MultipartFile file) {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String username = authentication.getName();

        documentService.uploadProfilePicture(username, file);

        String resultFilename = documentService.getProfilePictureFilename(username);
        Map<String, String> response = new HashMap<>();
        response.put("message", "Foto de perfil actualizada exitosamente.");
        response.put("rutaFoto", resultFilename);

        return ResponseEntity.ok(response);
    }

    // ─── Documentación laboral de empleados ──────────────────────────────────

    /**
     * Lista los documentos laborales de un empleado (excluye FOTO).
     */
    @GetMapping("/empleado/{idEmpleado}")
    @PreAuthorize("hasRole('ADMIN_MASTER') or hasRole('ADMIN_TECNICOS') or hasRole('ADMIN_CONTRATOS')")
    public ResponseEntity<List<DocumentoEmpleadoDTO>> getDocumentosEmpleado(
            @PathVariable(name = "idEmpleado") Integer idEmpleado) {
        return ResponseEntity.ok(documentService.getDocumentosEmpleado(idEmpleado));
    }

    /**
     * Sube un nuevo documento laboral al empleado.
     * El documento queda en estado PENDIENTE hasta que un admin lo valide.
     *
     * Parámetros multipart:
     * - file: archivo a subir
     * - idTipoDocumento: ID del tipo de documento
     * - numeroDocumento: número de referencia (ej. número de contrato)
     * - descripcion: descripción libre
     */
    @PostMapping("/empleado/{idEmpleado}/upload")
    @PreAuthorize("hasRole('ADMIN_MASTER') or hasRole('ADMIN_TECNICOS') or hasRole('ADMIN_CONTRATOS')")
    public ResponseEntity<DocumentoEmpleadoDTO> subirDocumentoEmpleado(
            @PathVariable(name = "idEmpleado") Integer idEmpleado,
            @RequestParam(name = "file") MultipartFile file,
            @RequestParam(name = "idTipoDocumento") Integer idTipoDocumento,
            @RequestParam(name = "numeroDocumento", required = false) String numeroDocumento,
            @RequestParam(name = "descripcion", required = false) String descripcion) {

        DocumentoEmpleadoDTO dto = documentService.subirDocumentoEmpleado(
                idEmpleado, file, idTipoDocumento, numeroDocumento, descripcion);
        return ResponseEntity.ok(dto);
    }

    /**
     * Cambia el estado de un documento de empleado.
     * Solo ADMIN_MASTER puede validar (cambiar a ACTIVO) un documento,
     * lo que habilita al empleado para recibir acceso al sistema.
     *
     * Body JSON: { "estado": "ACTIVO" | "PENDIENTE" | "RECHAZADO" }
     */
    @PutMapping("/empleado/docs/{idDocumento}/estado")
    @PreAuthorize("hasRole('ADMIN_MASTER') or hasRole('ADMIN_CONTRATOS')")
    public ResponseEntity<DocumentoEmpleadoDTO> cambiarEstadoDocumento(
            @PathVariable(name = "idDocumento") Integer idDocumento,
            @RequestBody Map<String, String> body) {

        String estado = body.get("estado");
        if (estado == null || estado.isBlank()) {
            return ResponseEntity.badRequest().build();
        }

        DocumentoEmpleadoDTO dto = documentService.cambiarEstadoDocumento(idDocumento, estado);
        return ResponseEntity.ok(dto);
    }

    /**
     * Elimina físicamente un documento del expediente.
     */
    @DeleteMapping("/empleado/docs/{idDocumento}")
    @PreAuthorize("hasRole('ADMIN_MASTER')")
    public ResponseEntity<Void> eliminarDocumentoEmpleado(@PathVariable(name = "idDocumento") Integer idDocumento) {
        documentService.eliminarDocumentoEmpleado(idDocumento);
        return ResponseEntity.noContent().build();
    }
}
