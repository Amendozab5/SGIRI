package com.apweb.backend.controller;

import com.apweb.backend.model.User;
import com.apweb.backend.model.VisitaTecnica;
import com.apweb.backend.payload.request.VisitaRequest;
import com.apweb.backend.payload.response.MessageResponse;
import com.apweb.backend.repository.UserRepository;
import com.apweb.backend.service.VisitaTecnicaService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;

@CrossOrigin(origins = "*", maxAge = 3600)
@RestController
@RequestMapping("/api/visitas")
public class VisitaTecnicaController {

    @Autowired
    private VisitaTecnicaService visitaTecnicaService;

    @Autowired
    private UserRepository userRepository;

    @GetMapping
    @PreAuthorize("hasRole('ADMIN_MASTER') or hasRole('ADMIN_TECNICOS') or hasRole('TECNICO')")
    public ResponseEntity<List<VisitaTecnica>> getVisitas(
            @RequestParam("start") String startStr,
            @RequestParam("end") String endStr) {

        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        boolean isAdmin = authentication.getAuthorities().stream()
                .anyMatch(a -> a.getAuthority().equals("ROLE_ADMIN") || a.getAuthority().equals("ROLE_ADMIN_MASTER") || a.getAuthority().equals("ROLE_ADMIN_TECNICOS"));

        // Angular envía ISO string completo (ej: 2026-03-08T05:00:00.000Z)
        LocalDate start = LocalDate.parse(startStr.substring(0, 10));
        LocalDate end = LocalDate.parse(endStr.substring(0, 10));

        if (isAdmin) {
            return ResponseEntity.ok(visitaTecnicaService.getVisitasByDateRange(start, end));
        } else {
            // Si es técnico (y no admin), solo ve sus propias visitas
            User currentUser = userRepository.findByUsername(authentication.getName())
                    .orElseThrow(() -> new RuntimeException("Error: Usuario no encontrado"));
            return ResponseEntity.ok(visitaTecnicaService.getVisitasByDateRangeAndTecnico(start, end, currentUser.getId()));
        }
    }

    @GetMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN_MASTER') or hasRole('ADMIN_TECNICOS') or hasRole('TECNICO')")
    public ResponseEntity<VisitaTecnica> getVisitaById(@PathVariable("id") Integer id) {
        return ResponseEntity.ok(visitaTecnicaService.getVisitaById(id));
    }

    @PostMapping
    @PreAuthorize("hasRole('ADMIN_MASTER') or hasRole('ADMIN_TECNICOS')")
    public ResponseEntity<?> createVisita(@Valid @RequestBody VisitaRequest request) {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        User currentUser = userRepository.findByUsername(authentication.getName())
                .orElseThrow(() -> new RuntimeException("Error: Usuario no encontrado"));

        VisitaTecnica visita = visitaTecnicaService.saveVisita(request, currentUser);
        return ResponseEntity.ok(new MessageResponse("Visita programada exitosamente con ID: " + visita.getIdVisita()));
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN_MASTER') or hasRole('ADMIN_TECNICOS') or hasRole('TECNICO')")
    public ResponseEntity<?> updateVisita(@PathVariable("id") Integer id, @Valid @RequestBody VisitaRequest request) {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        User currentUser = userRepository.findByUsername(authentication.getName())
                .orElseThrow(() -> new RuntimeException("Error: Usuario no encontrado"));

        visitaTecnicaService.updateVisita(id, request, currentUser);
        return ResponseEntity.ok(new MessageResponse("Visita actualizada exitosamente"));
    }
}
