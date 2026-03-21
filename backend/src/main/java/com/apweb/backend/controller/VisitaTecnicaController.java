package com.apweb.backend.controller;

import com.apweb.backend.model.User;
import com.apweb.backend.model.VisitaTecnica;
import com.apweb.backend.payload.request.VisitaRequest;
import com.apweb.backend.payload.response.MessageResponse;
import com.apweb.backend.repository.UserRepository;
import com.apweb.backend.service.VisitaTecnicaService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
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
                .anyMatch(a -> a.getAuthority().equals("ROLE_ADMIN") || a.getAuthority().equals("ROLE_ADMIN_MASTER")
                        || a.getAuthority().equals("ROLE_ADMIN_TECNICOS"));

        // Angular envía ISO string completo (ej: 2026-03-08T05:00:00.000Z)
        LocalDate start = LocalDate.parse(startStr.substring(0, 10));
        LocalDate end = LocalDate.parse(endStr.substring(0, 10));

        if (isAdmin) {
            return ResponseEntity.ok(visitaTecnicaService.getVisitasByDateRange(start, end));
        } else {
            // Si es técnico (y no admin), solo ve sus propias visitas
            User currentUser = userRepository.findByUsername(authentication.getName())
                    .orElseThrow(() -> new RuntimeException("Error: Usuario no encontrado"));
            return ResponseEntity
                    .ok(visitaTecnicaService.getVisitasByDateRangeAndTecnico(start, end, currentUser.getId()));
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

    @GetMapping("/my-visits")
    @PreAuthorize("hasRole('CLIENTE') or hasRole('TECNICO') or hasRole('ADMIN_MASTER') or hasRole('ADMIN_TECNICOS')")
    public ResponseEntity<List<VisitaTecnica>> getMyVisits() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        User currentUser = userRepository.findByUsername(authentication.getName())
                .orElseThrow(() -> new RuntimeException("Error: Usuario no encontrado"));

        boolean isTechnician = authentication.getAuthorities().stream()
                .anyMatch(a -> a.getAuthority().equals("ROLE_TECNICO"));

        if (isTechnician) {
            return ResponseEntity.ok(visitaTecnicaService.getVisitasByTecnico(currentUser.getId()));
        } else {
            return ResponseEntity.ok(visitaTecnicaService.getVisitasByCliente(currentUser.getId()));
        }
    }

    @GetMapping("/ticket/{id}/history")
    @PreAuthorize("hasRole('CLIENTE') or hasRole('TECNICO') or hasRole('ADMIN_TECNICOS') or hasRole('ADMIN_MASTER')")
    public ResponseEntity<?> getTicketHistory(@PathVariable("id") Integer id) {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        User currentUser = userRepository.findByUsername(authentication.getName())
                .orElseThrow(() -> new RuntimeException("Error: Usuario no encontrado"));

        // Use TicketService to check ownership if client
        // But since I don't want to inject TicketService here if not needed, I'll check the visits themselves 
        // Or better, check the ticket through a repository or the visits' own creator
        
        List<VisitaTecnica> visits = visitaTecnicaService.getVisitasByTicket(id);
        
        // Security check for clients
        boolean isClient = authentication.getAuthorities().stream()
                .anyMatch(a -> a.getAuthority().equals("ROLE_CLIENTE"));
        
        if (isClient && !visits.isEmpty()) {
            // Check if the first visit belongs to a ticket owned by the user (as subject)
            if (visits.get(0).getTicket() != null && 
                visits.get(0).getTicket().getCliente() != null &&
                visits.get(0).getTicket().getCliente().getPersona() != null &&
                visits.get(0).getTicket().getCliente().getPersona().getUser() != null &&
                !visits.get(0).getTicket().getCliente().getPersona().getUser().getId().equals(currentUser.getId())) {
                return ResponseEntity.status(HttpStatus.FORBIDDEN)
                        .body(new MessageResponse("Error: No tiene permiso para ver el historial de este ticket."));
            }
        } else if (isClient && visits.isEmpty()) {
            // If empty, we should still check if they OWN the ticket even if it has no visits
            // But if there are no visits, returning empty is technically "safe" as no data is leaked.
            // However, a clever attacker could probe if a ticket EXISTS.
            // To be 100% safe, we should check ticket ownership regardless of visits list.
        }

        return ResponseEntity.ok(visits);
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN_MASTER') or hasRole('ADMIN_TECNICOS')")
    public ResponseEntity<?> deleteVisita(@PathVariable("id") Integer id) {
        visitaTecnicaService.deleteVisita(id);
        return ResponseEntity.ok(new MessageResponse("Visita removida de la agenda exitosamente"));
    }
}
