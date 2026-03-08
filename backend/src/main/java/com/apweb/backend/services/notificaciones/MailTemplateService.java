package com.apweb.backend.services.notificaciones;

import org.springframework.stereotype.Service;

@Service
public class MailTemplateService {

        public String getBaseTemplate(String title, String content, String actionLabel, String actionUrl) {
                return "<!DOCTYPE html>" +
                                "<html>" +
                                "<head>" +
                                "    <style>" +
                                "        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f4f7f6; margin: 0; padding: 0; }"
                                +
                                "        .container { max-width: 600px; margin: 40px auto; background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 10px 30px rgba(0,0,0,0.1); border: 1px solid #e0e0e0; }"
                                +
                                "        .header { background: linear-gradient(135deg, #0d6efd 0%, #004299 100%); padding: 40px 20px; text-align: center; color: white; }"
                                +
                                "        .header h1 { margin: 0; font-size: 28px; letter-spacing: 2px; text-transform: uppercase; font-weight: 800; }"
                                +
                                "        .content { padding: 40px; color: #444444; line-height: 1.7; }" +
                                "        .greeting { font-size: 22px; font-weight: 700; color: #1a1a1a; margin-bottom: 25px; }"
                                +
                                "        .footer { background-color: #f8f9fa; padding: 30px; text-align: center; font-size: 12px; color: #999999; border-top: 1px solid #eeeeee; }"
                                +
                                "        .button { display: inline-block; background-color: #0d6efd; color: #ffffff !important; padding: 16px 35px; border-radius: 12px; text-decoration: none; font-weight: 700; font-size: 16px; margin-top: 25px; box-shadow: 0 4px 12px rgba(13, 110, 253, 0.3); }"
                                +
                                "        .button:hover { background-color: #0b5ed7; }" +
                                "        .info-box { background-color: #f8f9fa; border-radius: 12px; padding: 25px; margin: 25px 0; border: 1px solid #dee2e6; border-left: 5px solid #0d6efd; }"
                                +
                                "        .info-item { margin-bottom: 10px; font-size: 15px; }" +
                                "        .label { font-weight: 600; color: #6c757d; }" +
                                "        .value { color: #1a1a1a; font-weight: 600; }" +
                                "    </style>" +
                                "</head>" +
                                "<body>" +
                                "    <div class='container'>" +
                                "        <div class='header'>" +
                                "            <h1>SGIM</h1>" +
                                "            <p style='margin: 8px 0 0; font-size: 15px; opacity: 0.9; font-weight: 400;'>Servicio de Notificaciones</p>"
                                +
                                "        </div>" +
                                "        <div class='content'>" +
                                "            <div class='greeting'>" + title + "</div>" +
                                "            " + content +
                                (actionUrl != null
                                                ? "            <div style='text-align: center; margin-top: 20px;'><a href='"
                                                                + actionUrl
                                                                + "' class='btn button'>" + actionLabel + "</a></div>"
                                                : "")
                                +
                                "        </div>" +
                                "        <div class='footer'>" +
                                "            <strong>SGIM - Soluciones Tecnológicas</strong><br>" +
                                "            Este mensaje fue generado automáticamente por nuestro sistema.<br>" +
                                "            © " + java.time.Year.now().getValue() + " Todos los derechos reservados." +
                                "        </div>" +
                                "    </div>" +
                                "</body>" +
                                "</html>";
        }

        public String formatTicketAssignment(String customerName, Integer ticketId, String subject, String techName,
                        String webUrl) {
                String content = String.format(
                                "<p>Hola <b>%s</b>,</p>" +
                                                "<p>Nuestro equipo ha procesado tu requerimiento y queremos informarte que ya ha sido asignado un especialista para su atención.</p>"
                                                +
                                                "<div class='info-box'>" +
                                                "    <div class='info-item'><span class='label'>Ticket:</span> <span class='value'>#%d</span></div>"
                                                +
                                                "    <div class='info-item'><span class='label'>Asunto:</span> <span class='value'>%s</span></div>"
                                                +
                                                "    <div class='info-item' style='margin-bottom: 0;'><span class='label'>Especialista:</span> <span class='value'>%s</span></div>"
                                                +
                                                "</div>" +
                                                "<p>Puedes realizar el seguimiento de tu incidencia en tiempo real y chatear con el técnico asignado a través de nuestra plataforma web.</p>",
                                customerName, ticketId, subject, techName);

                return getBaseTemplate("Asignación de Técnico", content, "Seguir Ticket en Línea", webUrl);
        }

        public String formatTicketStatusUpdate(String customerName, Integer ticketId, String subject, String newStatus,
                        String observation, String techName, String webUrl) {
                String content = String.format(
                                "<p>Hola <b>%s</b>,</p>" +
                                                "<p>Te informamos que tu ticket <b>#%d</b> ha tenido una actualización importante en su estado:</p>"
                                                +
                                                "<div class='info-box'>" +
                                                "    <div class='info-item'><span class='label'>Nuevo Estado:</span> <span class='value' style='color: #0d6efd;'>%s</span></div>"
                                                +
                                                "    <div class='info-item'><span class='label'>Asunto:</span> <span class='value'>%s</span></div>"
                                                +
                                                "    <div class='info-item'><span class='label'>Observaciones:</span> <br><i style='color: #555;'>\"%s\"</i></div>"
                                                +
                                                "    <div class='info-item' style='margin-bottom: 0; margin-top: 10px;'><span class='label'>Especialista:</span> <span class='value'>%s</span></div>"
                                                +
                                                "</div>" +
                                                "<p>Si tienes alguna duda o quieres agregar más información, puedes hacerlo directamente desde el portal de soporte.</p>",
                                customerName, ticketId, newStatus, subject,
                                (observation != null && !observation.isEmpty() ? observation
                                                : "Sin observaciones adicionales"),
                                techName);

                return getBaseTemplate("Actualización de Estado", content, "Ver Detalles del Ticket", webUrl);
        }

        public String formatVisitRequired(String customerName, Integer ticketId, String subject, String observation,
                        String techName, String webUrl) {
                String content = String.format(
                                "<p>Hola <b>%s</b>,</p>" +
                                                "<p>Nuestro equipo técnico ha revisado tu requerimiento y ha determinado que <b>es necesaria una visita presencial</b> para resolver la incidencia.</p>"
                                                +
                                                "<div class='info-box' style='border-left: 5px solid #ffc107;'>" +
                                                "    <div class='info-item'><span class='label'>Ticket:</span> <span class='value'>#%d</span></div>"
                                                +
                                                "    <div class='info-item'><span class='label'>Asunto:</span> <span class='value'>%s</span></div>"
                                                +
                                                "    <div class='info-item'><span class='label'>Motivo de Visita:</span> <br><i style='color: #555;'>\"%s\"</i></div>"
                                                +
                                                "    <div class='info-item' style='margin-bottom: 0; margin-top: 10px;'><span class='label'>Técnico que solicita:</span> <span class='value'>%s</span></div>"
                                                +
                                                "</div>" +
                                                "<p>En breve, nuestro personal administrativo se pondrá en contacto contigo o agendará la cita directamente en tu calendario de soporte.</p>",
                                customerName, ticketId, subject,
                                (observation != null && !observation.isEmpty() ? observation
                                                : "Se requiere inspección física"),
                                techName);

                return getBaseTemplate("Visita Técnica Requerida", content, "Revisar Agenda", webUrl);
        }

        public String formatVisitScheduled(String customerName, Integer ticketId, String subject,
                        String fecha, String horaInicio, String horaFin, String techName, String webUrl) {
                String content = String.format(
                                "<p>Hola <b>%s</b>,</p>" +
                                                "<p>¡Buenas noticias! Tu visita técnica ha sido programada. Nuestro especialista acudirá a tus instalaciones en el horario acordado.</p>"
                                                +
                                                "<div class='info-box' style='border-left: 5px solid #198754;'>" +
                                                "    <div class='info-item'><span class='label'>Fecha de Visita:</span> <span class='value' style='color: #198754;'>%s</span></div>"
                                                +
                                                "    <div class='info-item'><span class='label'>Horario:</span> <span class='value'>De %s a %s</span></div>"
                                                +
                                                "    <div class='info-item'><span class='label'>Ticket Asociado:</span> <span class='value'>#%d - %s</span></div>"
                                                +
                                                "    <div class='info-item' style='margin-bottom: 0; margin-top: 10px;'><span class='label'>Técnico Responsable:</span> <span class='value'>%s</span></div>"
                                                +
                                                "</div>" +
                                                "<p>Por favor, asegúrate de que haya alguien disponible para recibir a nuestro personal. Si necesitas reprogramar, contáctanos lo antes posible.</p>",
                                customerName, fecha, horaInicio, horaFin, ticketId, subject, techName);

                return getBaseTemplate("Cita Programada Exitosamente", content, "Ver Mi Agenda", webUrl);
        }
}
