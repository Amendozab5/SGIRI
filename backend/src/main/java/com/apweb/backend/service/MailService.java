package com.apweb.backend.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.MailException;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.stereotype.Service;

import jakarta.mail.MessagingException;
import jakarta.mail.internet.MimeMessage;

@Service
public class MailService {

    private final JavaMailSender javaMailSender;

    @Value("${spring.mail.username}")
    private String fromEmail;

    private final Logger logger = LoggerFactory.getLogger(MailService.class);

    public MailService(JavaMailSender javaMailSender) {
        this.javaMailSender = javaMailSender;
    }

    public void sendEmail(String to, String subject, String body) {
        MimeMessage message = javaMailSender.createMimeMessage();
        try {
            MimeMessageHelper helper = new MimeMessageHelper(message, true);
            helper.setFrom(fromEmail);
            helper.setTo(to);
            helper.setSubject(subject);
            helper.setText(body, true); // true indicates HTML content

            logger.info("[Hilo: {}] Intentando enviar correo a {}...", Thread.currentThread().getName(), to);
            javaMailSender.send(message);
            logger.info("Email sent successfully to {} with subject: {}", to, subject);
        } catch (MessagingException | MailException e) {
            logger.error("Failed to send email to {} with subject: {}. Error: {}", to, subject, e.getMessage());
            throw new RuntimeException("Failed to send email: " + e.getMessage(), e);
        }
    }

    public String getWelcomeEmailTemplate(String nombre, String username, String password, boolean esEmpleado) {
        String subtitle = esEmpleado ? "Acceso de Colaborador" : "Acceso de Cliente";
        String messageHeader = esEmpleado ? "¡Hola, " + nombre + "!" : "¡Bienvenido, " + nombre + "!";
        String mainText = esEmpleado 
            ? "Tu ficha de colaborador ha sido validada y se ha habilitado tu acceso a la plataforma corporativa. Ya puedes comenzar a utilizar las herramientas internas del sistema."
            : "Es un placer saludarte. Tu cuenta ha sido activada en nuestra plataforma y ya puedes comenzar a gestionar tus requerimientos de forma rápida e eficiente.";

        return "<!DOCTYPE html>"
                + "<html>"
                + "<head>"
                + "    <style>"
                + "        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f4f7f6; margin: 0; padding: 0; }"
                + "        .container { max-width: 600px; margin: 40px auto; background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 10px 30px rgba(0,0,0,0.1); border: 1px solid #e0e0e0; }"
                + "        .header { background: linear-gradient(135deg, #0d6efd 0%, #004299 100%); padding: 40px 20px; text-align: center; color: white; }"
                + "        .header h1 { margin: 0; font-size: 28px; letter-spacing: 2px; text-transform: uppercase; font-weight: 800; }"
                + "        .content { padding: 40px; color: #444444; line-height: 1.7; }"
                + "        .greeting { font-size: 22px; font-weight: 700; color: #1a1a1a; margin-bottom: 25px; }"
                + "        .credential-box { background-color: #f8f9fa; border-radius: 12px; padding: 30px; margin: 30px 0; border: 1px solid #dee2e6; position: relative; }"
                + "        .credential-item { margin-bottom: 15px; font-size: 16px; }"
                + "        .label { font-weight: 600; color: #6c757d; display: inline-block; width: 100px; }"
                + "        .value { font-family: 'Consolas', 'Monaco', monospace; font-weight: 700; color: #0d6efd; font-size: 18px; background: #eef2ff; padding: 4px 10px; border-radius: 4px; }"
                + "        .btn { display: inline-block; background-color: #0d6efd; color: #ffffff !important; padding: 16px 35px; border-radius: 12px; text-decoration: none; font-weight: 700; font-size: 16px; margin-top: 25px; box-shadow: 0 4px 12px rgba(13, 110, 253, 0.3); }"
                + "        .notice { font-size: 14px; color: #dc3545; font-weight: 600; margin-top: 20px; padding: 10px; background-color: #fff5f5; border-radius: 8px; border-left: 4px solid #dc3545; }"
                + "        .footer { background-color: #f8f9fa; padding: 30px; text-align: center; font-size: 12px; color: #999999; border-top: 1px solid #eeeeee; }"
                + "    </style>"
                + "</head>"
                + "<body>"
                + "    <div class='container'>"
                + "        <div class='header'>"
                + "            <h1>SGIM</h1>"
                + "            <p style='margin: 8px 0 0; font-size: 15px; opacity: 0.9; font-weight: 400;'>" + subtitle + "</p>"
                + "        </div>"
                + "        <div class='content'>"
                + "            <div class='greeting'>" + messageHeader + "</div>"
                + "            <p>" + mainText + "</p>"
                + "            "
                + "            <p style='margin-top: 25px; font-weight: 600;'>Tus credenciales de acceso son:</p>"
                + "            "
                + "            <div class='credential-box'>"
                + "                <div class='credential-item'>"
                + "                    <span class='label'>Usuario:</span>"
                + "                    <span class='value'>" + username + "</span>"
                + "                </div>"
                + "                <div class='credential-item' style='margin-bottom: 0;'>"
                + "                    <span class='label'>Clave:</span>"
                + "                    <span class='value'>" + password + "</span>"
                + "                </div>"
                + "            </div>"
                + "            "
                + "            <div class='notice'>"
                + "                ⚠️ AVISO: Por seguridad, el sistema solicitará un cambio de contraseña obligatorio en tu primer ingreso."
                + "            </div>"
                + "            "
                + "            <div style='text-align: center; margin-top: 45px;'>"
                + "                <a href='http://localhost:4200/login' class='btn'>Acceder al Portal</a>"
                + "            </div>"
                + "        </div>"
                + "        <div class='footer'>"
                + "            <strong>SGIM - Soluciones Tecnológicas</strong><br>"
                + "            Este mensaje fue generado automáticamente por nuestro sistema.<br>"
                + "            © " + java.time.Year.now().getValue() + " Todos los derechos reservados."
                + "        </div>"
                + "    </div>"
                + "</body>"
                + "</html>";
    }
}
