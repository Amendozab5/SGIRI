package com.apweb.backend.service;

import com.apweb.backend.model.*;
import com.apweb.backend.repository.NotificacionRepository;
import com.apweb.backend.repository.CanalNotificacionRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;

@Service
public class NotificationService {

    @Autowired
    private NotificacionRepository notificacionRepository;

    @Autowired
    private CanalNotificacionRepository canalRepository;

    public void createNotification(User origin, User destination, Ticket ticket, String subject, String message) {
        // Find default canal (e.g., INTERNAL or SYSTEM)
        CanalNotificacion canal = canalRepository.findAll().stream()
                .findFirst()
                .orElse(null);

        if (canal == null) {
            System.err.println("WARNING: No notification channel found. Notification will not be saved.");
            return;
        }

        Notificacion notificacion = new Notificacion();
        notificacion.setUsuarioOrigen(origin);
        notificacion.setUsuarioDestino(destination);
        notificacion.setTicket(ticket);
        notificacion.setAsunto(subject);
        notificacion.setMensaje(message);
        notificacion.setDestinatario(destination.getUsername());
        notificacion.setCanal(canal);
        notificacion.setEnviado(false);
        notificacion.setIdEmpresa(ticket.getSucursal().getEmpresa().getId());
        notificacion.setFechaCreacion(LocalDateTime.now());

        notificacionRepository.save(notificacion);
    }
}
