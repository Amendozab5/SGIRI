package com.apweb.backend.services.notificaciones;

import com.apweb.backend.models.entities.notificaciones.NotificacionesColaCorreo;
import com.apweb.backend.repositories.notificaciones.NotificacionesColaCorreoRepository;
import com.apweb.backend.service.MailService;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;
import java.util.List;

@Component
@RequiredArgsConstructor
public class NotificacionScheduler {

    private final NotificacionesColaCorreoRepository colaCorreoRepository;
    private final MailService mailService;
    private final Logger logger = LoggerFactory.getLogger(NotificacionScheduler.class);

    // Se ejecuta cada 5 segundos
    @Scheduled(fixedDelay = 5000)
    public void procesarColaCorreos() {
        List<NotificacionesColaCorreo> pendientes = colaCorreoRepository.findByEnviadoFalse();

        if (pendientes.isEmpty()) {
            return;
        }

        logger.info("Procesando {} correos pendientes de envío...", pendientes.size());

        for (NotificacionesColaCorreo correo : pendientes) {
            try {
                // Intentar enviar el correo
                mailService.sendEmail(
                        correo.getDestinatario(),
                        correo.getAsunto(),
                        correo.getCuerpoHtml());

                // Actualizar registro como enviado
                correo.setEnviado(true);
                correo.setFechaEnvio(LocalDateTime.now());
                correo.setErrorEnvio(null);

            } catch (Exception e) {
                // Registrar el error e incrementar intentos
                correo.setIntentos(correo.getIntentos() + 1);
                correo.setErrorEnvio(e.getMessage());
                logger.error("Error al enviar correo ID {}: {}", correo.getId(), e.getMessage());
            }
        }

        colaCorreoRepository.saveAll(pendientes);
    }
}
