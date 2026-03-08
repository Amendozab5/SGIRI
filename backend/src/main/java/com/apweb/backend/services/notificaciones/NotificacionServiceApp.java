package com.apweb.backend.services.notificaciones;

import com.apweb.backend.models.entities.notificaciones.NotificacionWeb;
import com.apweb.backend.models.entities.notificaciones.NotificacionesColaCorreo;
import com.apweb.backend.model.Ticket;
import com.apweb.backend.model.User;
import com.apweb.backend.repositories.notificaciones.NotificacionWebRepository;
import com.apweb.backend.repositories.notificaciones.NotificacionesColaCorreoRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class NotificacionServiceApp {

    private final NotificacionWebRepository notificacionWebRepository;
    private final NotificacionesColaCorreoRepository colaCorreoRepository;
    private final com.apweb.backend.repository.EmpresaRepository empresaRepository;

    @Transactional
    public void crearNotificacionWeb(User destino, String titulo, String mensaje, String ruta, Ticket ticket) {
        if (destino == null)
            return;

        com.apweb.backend.model.Empresa empresa = null;
        if (destino.getIdEmpresa() != null) {
            empresa = empresaRepository.findById(destino.getIdEmpresa()).orElse(null);
        }
        // Fallback: Si el usuario no tiene empresa, usamos la del ticket
        if (empresa == null && ticket != null && ticket.getSucursal() != null) {
            empresa = ticket.getSucursal().getEmpresa();
        }

        NotificacionWeb noti = NotificacionWeb.builder()
                .usuarioDestino(destino)
                .empresa(empresa)
                .titulo(titulo)
                .mensaje(mensaje)
                .rutaRedireccion(ruta)
                .ticket(ticket)
                .leida(false)
                .build();
        notificacionWebRepository.save(noti);
    }

    @Transactional(readOnly = true)
    public java.util.List<com.apweb.backend.dto.NotificacionWebDTO> obtenerNotificacionesPorUsuario(User usuario) {
        return notificacionWebRepository.findByUsuarioDestinoOrderByFechaCreacionDesc(usuario)
                .stream()
                .map(n -> com.apweb.backend.dto.NotificacionWebDTO.builder()
                        .id(n.getId())
                        .titulo(n.getTitulo())
                        .mensaje(n.getMensaje())
                        .rutaRedireccion(n.getRutaRedireccion())
                        .idTicket(n.getTicket() != null ? n.getTicket().getIdTicket() : null)
                        .leida(n.getLeida())
                        .fechaCreacion(n.getFechaCreacion())
                        .build())
                .collect(java.util.stream.Collectors.toList());
    }

    @Transactional(readOnly = true)
    public long obtenerConteoNoLeidas(User usuario) {
        return notificacionWebRepository.countByUsuarioDestinoAndLeidaFalse(usuario);
    }

    @Transactional
    public void marcarComoLeida(Integer idNotificacion) {
        NotificacionWeb noti = notificacionWebRepository.findById(idNotificacion)
                .orElseThrow(() -> new RuntimeException("Notificación no encontrada"));
        noti.setLeida(true);
        noti.setFechaLectura(java.time.LocalDateTime.now());
        notificacionWebRepository.save(noti);
    }

    @Transactional
    public void marcarTodasComoLeidas(User usuario) {
        java.util.List<NotificacionWeb> noLeidas = notificacionWebRepository
                .findByUsuarioDestinoOrderByFechaCreacionDesc(usuario)
                .stream()
                .filter(n -> !n.getLeida())
                .collect(java.util.stream.Collectors.toList());

        noLeidas.forEach(n -> {
            n.setLeida(true);
            n.setFechaLectura(java.time.LocalDateTime.now());
        });
        notificacionWebRepository.saveAll(noLeidas);
    }

    @Transactional
    public void encolarCorreo(Ticket ticket, String destinatario, String asunto, String cuerpoHtml) {
        if (destinatario == null || destinatario.isEmpty())
            return;

        NotificacionesColaCorreo correo = NotificacionesColaCorreo.builder()
                .empresa(ticket.getSucursal().getEmpresa())
                .destinatario(destinatario)
                .asunto(asunto)
                .cuerpoHtml(cuerpoHtml)
                .enviado(false)
                .ticket(ticket)
                .build();
        colaCorreoRepository.save(correo);
    }
}
