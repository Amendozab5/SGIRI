package com.apweb.backend.controller;

import com.apweb.backend.model.Inventario;
import com.apweb.backend.repository.InventarioRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/inventario")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class InventarioController {

    private final InventarioRepository inventarioRepository;

    @GetMapping
    @PreAuthorize("hasRole('ROLE_TECNICO') or hasRole('ROLE_ADMIN_MASTER') or hasRole('ROLE_ADMIN_TECNICOS')")
    public ResponseEntity<List<Inventario>> getInventario() {
        return ResponseEntity.ok(inventarioRepository.findByActivoTrueOrderByNombreAsc());
    }
}
