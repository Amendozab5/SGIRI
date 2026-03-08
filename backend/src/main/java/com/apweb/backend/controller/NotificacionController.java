package com.apweb.backend.controller;

import com.apweb.backend.model.User;
import com.apweb.backend.repository.UserRepository;
import com.apweb.backend.services.notificaciones.NotificacionServiceApp;
import com.apweb.backend.dto.NotificacionWebDTO;
import com.apweb.backend.payload.response.MessageResponse;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@CrossOrigin(origins = "*", maxAge = 3600)
@RestController
@RequestMapping("/api/notificaciones")
public class NotificacionController {

    @Autowired
    private NotificacionServiceApp notificacionService;

    @Autowired
    private UserRepository userRepository;

    @GetMapping("/mis-notificaciones")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<List<NotificacionWebDTO>> getMisNotificaciones() {
        User currentUser = getCurrentUser();
        return ResponseEntity.ok(notificacionService.obtenerNotificacionesPorUsuario(currentUser));
    }

    @GetMapping("/unread-count")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<Map<String, Long>> getUnreadCount() {
        User currentUser = getCurrentUser();
        long count = notificacionService.obtenerConteoNoLeidas(currentUser);
        return ResponseEntity.ok(Map.of("unreadCount", count));
    }

    @PatchMapping("/{id}/leer")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<?> marcarComoLeida(@PathVariable(name = "id") Integer id) {
        notificacionService.marcarComoLeida(id);
        return ResponseEntity.ok(new MessageResponse("Notificación marcada como leída"));
    }

    @PatchMapping("/leer-todas")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<?> marcarTodasComoLeidas() {
        User currentUser = getCurrentUser();
        notificacionService.marcarTodasComoLeidas(currentUser);
        return ResponseEntity.ok(new MessageResponse("Todas las notificaciones han sido marcadas como leídas"));
    }

    private User getCurrentUser() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String currentUserName = authentication.getName();
        return userRepository.findByUsername(currentUserName)
                .orElseThrow(() -> new RuntimeException("Error: User not found"));
    }
}
