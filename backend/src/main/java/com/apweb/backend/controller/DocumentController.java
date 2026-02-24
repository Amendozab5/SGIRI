package com.apweb.backend.controller;

import com.apweb.backend.service.DocumentService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import java.util.HashMap;
import java.util.Map;

@CrossOrigin(origins = "*", maxAge = 3600)
@RestController
@RequestMapping("/api/documents")
public class DocumentController {

    private final DocumentService documentService;

    public DocumentController(DocumentService documentService) {
        this.documentService = documentService;
    }

    @PostMapping("/upload-photo")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<Map<String, String>> uploadPhoto(@RequestParam("file") MultipartFile file) {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String username = authentication.getName();

        documentService.uploadProfilePicture(username, file);

        String resultFilename = documentService.getProfilePictureFilename(username);
        Map<String, String> response = new HashMap<>();
        response.put("message", "Foto de perfil actualizada exitosamente.");
        response.put("rutaFoto", resultFilename);

        return ResponseEntity.ok(response);
    }
}
