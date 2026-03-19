package com.apweb.backend.service;

import com.apweb.backend.model.*;
import com.apweb.backend.payload.request.VisitaRequest;
import com.apweb.backend.repository.*;
import com.apweb.backend.services.notificaciones.NotificacionServiceApp;
import com.apweb.backend.services.notificaciones.MailTemplateService;
import jakarta.transaction.Transactional;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import com.apweb.backend.util.AuditAccion;
import com.apweb.backend.util.AuditModulo;
import org.springframework.scheduling.annotation.Scheduled;

import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;
import java.util.Optional;
import java.util.Map;
import java.util.stream.Collectors;

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

        @Autowired
        private AuditService auditService;

        @Transactional
        public List<VisitaTecnica> getVisitasByDateRange(LocalDate start, LocalDate end) {
                return visitaTecnicaRepository.findByFechaVisitaBetween(start, end);
        }

        @Transactional
        public List<VisitaTecnica> getVisitasByDateRangeAndTecnico(LocalDate start, LocalDate end, Integer tecnicoId) {
                return visitaTecnicaRepository.findByFechaVisitaBetweenAndTecnico_Id(start, end, tecnicoId);
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

                // Validar que NO exista ya una visita activa para este ticket (PROGRAMADA, CONFIRMADA, etc.)
                // para evitar duplicidad accidental.
                List<VisitaTecnica> existingVisitas = visitaTecnicaRepository.findByTicket_IdTicketOrderByFechaVisitaDesc(ticket.getIdTicket());
                boolean hasActiveVisit = existingVisitas.stream()
                        .anyMatch(v -> v.getEstado() != null && 
                                  !v.getEstado().getCodigo().equals("CANCELADA") && 
                                  !v.getEstado().getCodigo().equals("FINALIZADA"));
                
                if (hasActiveVisit) {
                    throw new RuntimeException("Error: El ticket ya tiene una visita técnica activa programada.");
                }

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

                // --- CRITICO: Asegurar que el ticket esté asignado al técnico de la visita ---
                // Si el ticket no tenía técnico (por remoción previa) o tenía otro, lo actualizamos.
                if (ticket.getUsuarioAsignado() == null || !ticket.getUsuarioAsignado().getId().equals(tecnico.getId())) {
                    ticket.setUsuarioAsignado(tecnico);
                    ticketRepository.save(ticket);
                }

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
                                        "http://localhost:4200/home/user/ticket/" + ticket.getIdTicket());

                        notificacionServiceApp.encolarCorreo(ticket, emailCliente, subject, body);
                }

                // ── AUDITORÍA: Programación de Visita ───────────────────────────────
                auditService.registrarEventoContextual(
                                AuditModulo.VISITAS,
                                "soporte", "visita_tecnica",
                                savedVisita.getIdVisita(),
                                AuditAccion.INSERT,
                                "Programación de visita técnica para el ticket: #" + ticket.getIdTicket(),
                                null,
                                java.util.Map.of(
                                                "id_ticket", ticket.getIdTicket(),
                                                "id_tecnico", tecnico.getId(),
                                                "fecha", visita.getFechaVisita().toString()));
                // ────────────────────────────────────────────────────────────────────

                return savedVisita;
        }

        @Transactional
        public VisitaTecnica updateVisita(Integer id, VisitaRequest request, User updater) {
                VisitaTecnica visita = getVisitaById(id);

                if (request.getFechaVisita() != null) {
                        visita.setFechaVisita(request.getFechaVisita());
                }
                if (request.getHoraInicio() != null) {
                        visita.setHoraInicio(request.getHoraInicio());
                }
                if (request.getHoraFin() != null) {
                        visita.setHoraFin(request.getHoraFin());
                }
                if (request.getCodigoEstado() != null) {
                        CatalogoItem estadoNuevo = catalogoItemRepository
                                        .findByCatalogo_NombreAndCodigo("ESTADO_VISITA", request.getCodigoEstado())
                                        .orElseThrow(() -> new RuntimeException("Error: Estado de visita no encontrado"));
                        visita.setEstado(estadoNuevo);
                }
                if (request.getReporteVisita() != null) {
                        visita.setReporteVisita(request.getReporteVisita());
                }

                // Si se cambia el técnico, notificar al nuevo
                if (request.getIdTecnico() != null && !visita.getTecnico().getId().equals(request.getIdTecnico())) {
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

                // --- CRITICO: Asegurar que el ticket esté asignado al técnico de la visita ---
                // Si el ticket no tenía técnico (por remoción/cancelación previa de visita) o tenía otro, lo actualizamos.
                Ticket ticket = savedVisita.getTicket();
                if (ticket.getUsuarioAsignado() == null || !ticket.getUsuarioAsignado().getId().equals(savedVisita.getTecnico().getId())) {
                    ticket.setUsuarioAsignado(savedVisita.getTecnico());
                    ticketRepository.save(ticket);
                }

                // Notificar al CLIENTE de la actualización/reprogramación
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
                                        "http://localhost:4200/home/user/ticket/" + ticket.getIdTicket());

                        notificacionServiceApp.encolarCorreo(ticket, emailCliente, subject, body);
                }

                // ── AUDITORÍA: Actualización/Reprogramación de Visita ───────────────
                boolean esReprogramacion = !visita.getFechaVisita().equals(request.getFechaVisita()) ||
                                !visita.getHoraInicio().equals(request.getHoraInicio()) ||
                                (visita.getHoraFin() != null && !visita.getHoraFin().equals(request.getHoraFin()));

                String obsAudit = esReprogramacion ? "Reprogramación de visita técnica"
                                : "Actualización de visita técnica";

                auditService.registrarEventoContextual(
                                AuditModulo.VISITAS,
                                "soporte", "visita_tecnica",
                                savedVisita.getIdVisita(),
                                AuditAccion.UPDATE,
                                obsAudit,
                                java.util.Map.of(
                                                "fecha_ant", visita.getFechaVisita().toString(),
                                                "hora_ant", visita.getHoraInicio().toString()),
                                java.util.Map.of(
                                                "fecha_nueva", request.getFechaVisita().toString(),
                                                "hora_nueva", request.getHoraInicio().toString(),
                                                "id_tecnico", request.getIdTecnico()));
                // ────────────────────────────────────────────────────────────────────

                return savedVisita;
        }

        @Transactional
        public List<VisitaTecnica> getVisitasByCliente(Integer userId) {
                return visitaTecnicaRepository.findByTicket_UsuarioCreador_IdWithAssociations(userId);
        }

        @Transactional
        public List<VisitaTecnica> getVisitasByTicket(Integer idTicket) {
                return visitaTecnicaRepository.findByTicket_IdTicketOrderByFechaVisitaDesc(idTicket);
        }

        @Transactional
        public List<VisitaTecnica> getVisitasByTecnico(Integer tecnicoId) {
                List<VisitaTecnica> visitas = visitaTecnicaRepository.findByTecnico_IdWithAssociations(tecnicoId);
                for (VisitaTecnica v : visitas) {
                    loadVisitaDeep(v);
                }
                return visitas;
        }

        @Transactional
        @Scheduled(cron = "0 0 1 * * ?") // Ejecutar cada día a la 1 AM
        public void processExpiredVisits() {
                LocalDate today = LocalDate.now();
                List<VisitaTecnica> pendingOrProgrammed = visitaTecnicaRepository.findAll().stream()
                        .filter(v -> v.getFechaVisita().isBefore(today))
                        .filter(v -> !v.getEstado().getCodigo().equals("FINALIZADA") && 
                                    !v.getEstado().getCodigo().equals("CANCELADA") &&
                                    !v.getEstado().getCodigo().equals("EXPIRADA"))
                        .toList();

                if (pendingOrProgrammed.isEmpty()) return;

                CatalogoItem estadoExpirado = catalogoItemRepository
                        .findByCatalogo_NombreAndCodigo("ESTADO_VISITA", "EXPIRADA")
                        .orElseThrow(() -> new RuntimeException("Error: Estado EXPIRADA no encontrado"));

                for (VisitaTecnica v : pendingOrProgrammed) {
                        v.setEstado(estadoExpirado);
                        visitaTecnicaRepository.save(v);

                        Ticket t = v.getTicket();
                        if (t != null) {
                                t.setUsuarioAsignado(null);
                                ticketRepository.save(t);
                        }
                        
                        auditService.registrarEventoContextual(
                                AuditModulo.VISITAS,
                                "sistema", "visita_tecnica",
                                v.getIdVisita(),
                                AuditAccion.UPDATE,
                                "Visita marcada como EXPIRADA automáticamente por el sistema.",
                                null, null);
                }
        }

        @Transactional
        public void deleteVisita(Integer idVisita) {
                VisitaTecnica visita = getVisitaById(idVisita);
                Ticket ticket = visita.getTicket();

                // 1. Marcar la visita como CANCELADA en el catálogo
                CatalogoItem estadoCancelado = catalogoItemRepository
                                .findByCatalogo_NombreAndCodigo("ESTADO_VISITA", "CANCELADA")
                                .orElseThrow(() -> new RuntimeException("Error: Estado CANCELADA no encontrado"));
                visita.setEstado(estadoCancelado);
                visitaTecnicaRepository.save(visita);

                // 2. Desvincular al técnico del ticket para que vuelva a estar totalmente pendiente
                if (ticket != null) {
                        ticket.setUsuarioAsignado(null);
                        ticketRepository.save(ticket);
                }

                // 3. Registrar en Auditoría
                auditService.registrarEventoContextual(
                                AuditModulo.VISITAS,
                                "soporte", "visita_tecnica",
                                visita.getIdVisita(),
                                AuditAccion.DELETE,
                                "Visita técnica removida de la agenda (ID: " + idVisita + "). Ticket #"
                                                + (ticket != null ? ticket.getIdTicket() : "N/A"),
                                null,
                                java.util.Map.of(
                                                "id_ticket", (ticket != null ? ticket.getIdTicket() : "N/A"),
                                                "id_tecnico_anterior", visita.getTecnico().getId()));
        }

        private void loadVisitaDeep(VisitaTecnica v) {
            if (v == null) return;
            if (v.getEstado() != null) v.getEstado().getNombre();
            
            Ticket t = v.getTicket();
            if (t != null) {
                if (t.getEstadoItem() != null) t.getEstadoItem().getNombre();
                if (t.getPrioridadItem() != null) t.getPrioridadItem().getNombre();
                if (t.getSucursal() != null) t.getSucursal().getNombre();
                if (t.getCliente() != null && t.getCliente().getPersona() != null) {
                    t.getCliente().getPersona().getNombre();
                }
            }
            
            if (v.getTecnico() != null) {
                v.getTecnico().getUsername();
                if (v.getTecnico().getPersona() != null) v.getTecnico().getPersona().getNombre();
            }
        }
}
