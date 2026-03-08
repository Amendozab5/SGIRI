package com.apweb.backend.service;

import com.apweb.backend.model.*;
import com.apweb.backend.payload.request.VisitaRequest;
import com.apweb.backend.repository.*;
import com.apweb.backend.services.notificaciones.NotificacionServiceApp;
import com.apweb.backend.services.notificaciones.MailTemplateService;
import jakarta.transaction.Transactional;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.List;

@Service
public class VisitaTecnicaService {

        @Autowired
        private VisitaTecnicaRepository visitaTecnicaRepository;

        @Autowired
        private TicketRepository ticketRepository;

        @Autowired
        private UserRepository userRepository;

        @Autowired
        private EmpresaRepository empresaRepository;

        @Autowired
        private CatalogoItemRepository catalogoItemRepository;

        @Autowired
        private NotificacionServiceApp notificacionServiceApp;

        @Autowired
        private MailTemplateService mailTemplateService;

        @Transactional
        public List<VisitaTecnica> getVisitasByDateRange(LocalDate start, LocalDate end) {
                return visitaTecnicaRepository.findByFechaVisitaBetween(start, end);
        }

        public VisitaTecnica getVisitaById(Integer id) {
                return visitaTecnicaRepository.findById(id)
                                .orElseThrow(() -> new RuntimeException("Error: Visita no encontrada con ID: " + id));
        }

        @Transactional
        public VisitaTecnica saveVisita(VisitaRequest request, User creator) {
                Ticket ticket = ticketRepository.findById(request.getIdTicket())
                                .orElseThrow(() -> new RuntimeException("Error: Ticket no encontrado"));

                User tecnico = userRepository.findById(request.getIdTecnico())
                                .orElseThrow(() -> new RuntimeException("Error: Técnico no encontrado"));

                Empresa empresa = empresaRepository.findById(request.getIdEmpresa())
                                .orElseThrow(() -> new RuntimeException("Error: Empresa no encontrada"));

                CatalogoItem estado = catalogoItemRepository
                                .findByCatalogo_NombreAndCodigo("ESTADO_VISITA", request.getCodigoEstado())
                                .orElseThrow(() -> new RuntimeException("Error: Estado de visita no encontrado"));

                VisitaTecnica visita = VisitaTecnica.builder()
                                .ticket(ticket)
                                .tecnico(tecnico)
                                .empresa(empresa)
                                .fechaVisita(request.getFechaVisita())
                                .horaInicio(request.getHoraInicio())
                                .horaFin(request.getHoraFin())
                                .estado(estado)
                                .reporteVisita(request.getReporteVisita())
                                .build();

                VisitaTecnica savedVisita = visitaTecnicaRepository.save(visita);

                // Notificar al técnico (Web Interactiva)
                String rutaTecnico = "/home/agenda";
                notificacionServiceApp.crearNotificacionWeb(
                                tecnico,
                                "Nueva Visita Programada: Ticket #" + ticket.getIdTicket(),
                                "Se le ha programado una visita para el " + visita.getFechaVisita() + " a las "
                                                + visita.getHoraInicio(),
                                rutaTecnico,
                                ticket);

                // Notificar al CLIENTE (Correo Electrónico)
                User clienteApp = ticket.getUsuarioCreador();
                if (clienteApp != null && clienteApp.getPersona() != null) {
                        String emailCliente = clienteApp.getPersona().getCorreo();
                        String nombreCliente = clienteApp.getPersona().getNombre();
                        String subject = "Cita Programada: Visita Técnica para Ticket #" + ticket.getIdTicket();
                        String body = mailTemplateService.formatVisitScheduled(
                                        nombreCliente,
                                        ticket.getIdTicket(),
                                        ticket.getAsunto(),
                                        visita.getFechaVisita().toString(),
                                        visita.getHoraInicio().toString(),
                                        (visita.getHoraFin() != null ? visita.getHoraFin().toString() : "--:--"),
                                        (tecnico.getPersona() != null
                                                        ? tecnico.getPersona().getNombre() + " "
                                                                        + tecnico.getPersona().getApellido()
                                                        : tecnico.getUsername()),
                                        "http://localhost:4200/cliente/tickets/detalle/" + ticket.getIdTicket());

                        notificacionServiceApp.encolarCorreo(ticket, emailCliente, subject, body);
                }

                return savedVisita;
        }

        @Transactional
        public VisitaTecnica updateVisita(Integer id, VisitaRequest request, User updater) {
                VisitaTecnica visita = getVisitaById(id);

                CatalogoItem estadoNuevo = catalogoItemRepository
                                .findByCatalogo_NombreAndCodigo("ESTADO_VISITA", request.getCodigoEstado())
                                .orElseThrow(() -> new RuntimeException("Error: Estado de visita no encontrado"));

                visita.setFechaVisita(request.getFechaVisita());
                visita.setHoraInicio(request.getHoraInicio());
                visita.setHoraFin(request.getHoraFin());
                visita.setEstado(estadoNuevo);
                visita.setReporteVisita(request.getReporteVisita());

                // Si se cambia el técnico, notificar al nuevo
                if (!visita.getTecnico().getId().equals(request.getIdTecnico())) {
                        User nuevoTecnico = userRepository.findById(request.getIdTecnico())
                                        .orElseThrow(() -> new RuntimeException("Error: Nuevo técnico no encontrado"));
                        visita.setTecnico(nuevoTecnico);

                        String rutaTecnico = "/home/agenda";
                        notificacionServiceApp.crearNotificacionWeb(
                                        nuevoTecnico,
                                        "Visita Técnica Reasignada: Ticket #" + visita.getTicket().getIdTicket(),
                                        "Se le ha reasignado una visita para el " + visita.getFechaVisita(),
                                        rutaTecnico,
                                        visita.getTicket());
                }

                VisitaTecnica savedVisita = visitaTecnicaRepository.save(visita);

                // Notificar al CLIENTE de la actualización/reprogramación
                Ticket ticket = savedVisita.getTicket();
                User clienteApp = ticket.getUsuarioCreador();
                if (clienteApp != null && clienteApp.getPersona() != null) {
                        String emailCliente = clienteApp.getPersona().getCorreo();
                        String nombreCliente = clienteApp.getPersona().getNombre();
                        String subject = "Actualización de Cita: Visita Técnica para Ticket #" + ticket.getIdTicket();
                        String body = mailTemplateService.formatVisitScheduled(
                                        nombreCliente,
                                        ticket.getIdTicket(),
                                        ticket.getAsunto(),
                                        savedVisita.getFechaVisita().toString(),
                                        savedVisita.getHoraInicio().toString(),
                                        (savedVisita.getHoraFin() != null ? savedVisita.getHoraFin().toString()
                                                        : "--:--"),
                                        (savedVisita.getTecnico().getPersona() != null
                                                        ? savedVisita.getTecnico().getPersona().getNombre() + " "
                                                                        + savedVisita.getTecnico().getPersona()
                                                                                        .getApellido()
                                                        : savedVisita.getTecnico().getUsername()),
                                        "http://localhost:4200/cliente/tickets/detalle/" + ticket.getIdTicket());

                        notificacionServiceApp.encolarCorreo(ticket, emailCliente, subject, body);
                }

                return savedVisita;
        }
}
