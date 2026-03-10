package com.apweb.backend.service;

import com.apweb.backend.model.*;
import com.apweb.backend.payload.request.InformeTrabajoTecnicoRequest;
import com.apweb.backend.payload.request.TicketRequest;
import com.apweb.backend.repository.*;
import com.apweb.backend.services.notificaciones.NotificacionServiceApp;
import com.apweb.backend.services.notificaciones.MailTemplateService;
import java.io.ByteArrayInputStream;
import jakarta.transaction.Transactional;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.util.Optional;
import java.time.LocalDateTime;
import com.apweb.backend.util.AuditAccion;
import com.apweb.backend.util.AuditModulo;

@Service
public class TicketService {

        @Autowired
        private TicketRepository ticketRepository;

        @Autowired
        private EmpresaRepository empresaRepository;

        @Autowired
        private ClienteRepository clienteRepository;

        @Autowired
        private CatalogoItemRepository catalogoItemRepository;

        @Autowired
        private SucursalRepository sucursalRepository;

        @Autowired
        private ServicioRepository servicioRepository;

        @Autowired
        private UserRepository userRepository;

        @Autowired
        private AsignacionRepository asignacionRepository;

        @Autowired
        private ComentarioTicketRepository comentarioTicketRepository;

        @Autowired
        private HistorialEstadoRepository historialEstadoRepository;

        @Autowired
        private UsuarioBdRepository usuarioBdRepository;

        @Autowired
        private NotificacionServiceApp notificacionServiceApp;

        @Autowired
        private MailTemplateService mailTemplateService;

        @Autowired
        private AuditService auditService;

        @Autowired
        private InformeTrabajoTecnicoRepository informeTrabajoTecnicoRepository;

        @Autowired
        private InventarioRepository inventarioRepository;

        @Autowired
        private InventarioUsadoTicketRepository inventarioUsadoTicketRepository;

        public List<Ticket> getAllTickets() {
                return ticketRepository.findAllWithAssociations();
        }

        public List<Ticket> getTicketsByUser(User user) {
                return ticketRepository.findByUsuarioCreador(user);
        }

        @org.springframework.transaction.annotation.Transactional(readOnly = true)
        public org.springframework.data.domain.Page<Ticket> getTicketsByUserPaginated(
                        User user, String searchTerm, Integer statusId, Integer categoryId,
                        org.springframework.data.domain.Pageable pageable) {
                return ticketRepository.findByUsuarioCreadorWithFilters(user, searchTerm, statusId, categoryId,
                                pageable);
        }

        @Transactional
        public Ticket getTicketById(Integer id) {
                Ticket ticket = ticketRepository.findById(id)
                                .orElseThrow(() -> new RuntimeException("Error: Ticket not found with ID: " + id));
                // Force loading of lazy fields for the controller response
                if (ticket.getCliente() != null && ticket.getCliente().getPersona() != null) {
                        ticket.getCliente().getPersona().getNombre();
                }

                if (ticket.getHistorialEstados() != null) {
                        ticket.getHistorialEstados().forEach(h -> {
                                if (h.getEstado() != null)
                                        h.getEstado().getNombre();
                                if (h.getEstadoNuevo() != null)
                                        h.getEstadoNuevo().getNombre();
                        });
                }

                if (ticket.getComentarios() != null) {
                        ticket.getComentarios().forEach(c -> {
                                if (c.getUsuario() != null)
                                        c.getUsuario().getUsername();
                        });
                }

                return ticket;
        }

        public List<Ticket> getTicketsByAssignedUser(User user) {
                return ticketRepository.findByUsuarioAsignado(user);
        }

        @Transactional
        public Ticket assignTicket(Integer idTicket, Integer idUser, User assigner) {
                Ticket ticket = getTicketById(idTicket);
                User technician = userRepository.findById(idUser)
                                .orElseThrow(() -> new RuntimeException("Error: User not found with ID: " + idUser));

                CatalogoItem estadoAnterior = ticket.getEstadoItem();
                CatalogoItem estadoAsignado = catalogoItemRepository
                                .findByCatalogo_NombreAndCodigo("ESTADO_TICKET", "ASIGNADO")
                                .orElseThrow(() -> new RuntimeException("Error: Status 'ASIGNADO' not found"));

                // Update ticket
                User previousAssignee = ticket.getUsuarioAsignado();
                ticket.setUsuarioAsignado(technician);
                ticket.setEstadoItem(estadoAsignado);

                // Create assignment record
                Asignacion asignacion = new Asignacion();
                asignacion.setTicket(ticket);
                asignacion.setUsuario(technician);
                asignacion.setActivo(true);
                asignacionRepository.save(asignacion);

                // Record history
                HistorialEstado historial = new HistorialEstado();
                historial.setTicket(ticket);
                historial.setEstado(estadoAsignado);
                historial.setEstadoAnterior(estadoAnterior);
                historial.setEstadoNuevo(estadoAsignado);
                historial.setUsuario(assigner);
                historial.setUsuarioBd(resolveDbUsername(assigner));
                historial.setObservacion("Ticket asignado a " + technician.getUsername());
                historialEstadoRepository.save(historial);

                // ── AUDITORÍA: Cambio de Estado y Asignación ────────────────────────
                auditService.registrarCambioEstadoTicket(
                                ticket.getIdTicket(),
                                estadoAnterior.getId(),
                                estadoAsignado.getId(),
                                resolveDbUsername(assigner),
                                assigner.getId());

                auditService.registrarEvento(
                                AuditModulo.TICKETS,
                                "soporte", "ticket",
                                ticket.getIdTicket(),
                                AuditAccion.UPDATE,
                                "Ticket asignado o reasignado al técnico: " + technician.getUsername(),
                                previousAssignee != null
                                                ? java.util.Map.of("idUsuarioAsignadoAnterior",
                                                                previousAssignee.getId())
                                                : null,
                                java.util.Map.of("idUsuarioAsignadoNuevo", technician.getId()),
                                assigner.getId());
                // ────────────────────────────────────────────────────────────────────

                // Guardar cambios en el ticket primero
                Ticket savedTicket = ticketRepository.save(ticket);

                // --- NUEVO SISTEMA DE NOTIFICACIONES ---

                // 1. Notificar al Técnico (Solo Web + Interactiva)
                String rutaTecnico = "/home/user/ticket/" + savedTicket.getIdTicket();
                notificacionServiceApp.crearNotificacionWeb(
                                technician,
                                "Nuevo Ticket Asignado: #" + savedTicket.getIdTicket(),
                                "Se le ha asignado el ticket: " + savedTicket.getAsunto(),
                                rutaTecnico,
                                savedTicket);

                // 2. Notificar al Usuario Reportante (Web Interactiva + Correo)
                User usuarioReportante = savedTicket.getUsuarioCreador();
                if (usuarioReportante != null) {
                        String rutaUsuario = "/home/user/ticket/" + savedTicket.getIdTicket();

                        // Notificación Web (Segura contra Null)
                        String nombreTecnico = getNombreCompleto(technician);
                        notificacionServiceApp.crearNotificacionWeb(
                                        usuarioReportante,
                                        "Su ticket #" + savedTicket.getIdTicket() + " ha sido asignado",
                                        "Su ticket ahora está siendo atendido por " + nombreTecnico,
                                        rutaUsuario,
                                        savedTicket);

                        // Encolar Correo (Seguro contra Null)
                        String emailDestino = getEmailSeguro(usuarioReportante);
                        if (emailDestino != null) {
                                String urlFront = "http://localhost:4200/home/user/ticket/"
                                                + savedTicket.getIdTicket();
                                String cuerpoMail = mailTemplateService.formatTicketAssignment(
                                                getNombreCompleto(usuarioReportante),
                                                savedTicket.getIdTicket(),
                                                savedTicket.getAsunto(),
                                                nombreTecnico,
                                                urlFront);

                                notificacionServiceApp.encolarCorreo(
                                                savedTicket,
                                                emailDestino,
                                                "Ticket #" + savedTicket.getIdTicket() + " - Técnico Asignado",
                                                cuerpoMail);
                        }
                }

                return savedTicket;
        }

        @Transactional
        public Ticket createTicketForClient(User user, TicketRequest ticketRequest) {
                // 1. Identify Client
                Cliente cliente = clienteRepository.findByPersona_User(user)
                                .orElseThrow(() -> new RuntimeException(
                                                "Error: Logged user is not a registered client"));

                // 2. Fetch required entities
                Sucursal sucursal = null;
                if (ticketRequest.getIdSucursal() != null) {
                        sucursal = sucursalRepository.findById(ticketRequest.getIdSucursal())
                                        .orElseThrow(() -> new RuntimeException("Error: Sucursal not found"));
                } else if (cliente.getSucursal() != null) {
                        sucursal = cliente.getSucursal();
                } else {
                        throw new RuntimeException("Error: Sucursal not found and not assigned to client");
                }

                // If idServicio is not provided, we might need a default or error
                // For now, let's assume it's provided or we pick the first one from the company
                // if multiple
                Servicio servicio = null;
                if (ticketRequest.getIdServicio() != null) {
                        servicio = servicioRepository.findById(ticketRequest.getIdServicio())
                                        .orElseThrow(() -> new RuntimeException("Error: Servicio not found"));
                }

                // 3. Automatically assign Catalog Items (Masters)
                CatalogoItem estadoAbierto = catalogoItemRepository
                                .findByCatalogo_NombreAndCodigo("ESTADO_TICKET", "ABIERTO")
                                .orElseThrow(() -> new RuntimeException(
                                                "Error: Status 'ABIERTO' not found in catalog"));

                CatalogoItem prioridadBaja = catalogoItemRepository
                                .findByCatalogo_NombreAndCodigo("PRIORIDAD_TICKET", "BAJA")
                                .orElseThrow(() -> new RuntimeException("Error: Priority 'BAJA' not found in catalog"));

                CatalogoItem categoriaItem = catalogoItemRepository.findById(ticketRequest.getIdCategoriaItem())
                                .orElseThrow(() -> new RuntimeException("Error: CategoriaItem not found"));

                // 4. Create Ticket
                Ticket ticket = Ticket.builder()
                                .asunto(ticketRequest.getAsunto())
                                .descripcion(ticketRequest.getDescripcion())
                                .cliente(cliente)
                                .usuarioCreador(user)
                                .sucursal(sucursal)
                                .servicio(servicio)
                                .estadoItem(estadoAbierto)
                                .prioridadItem(prioridadBaja)
                                .categoriaItem(categoriaItem)
                                .build();

                Ticket savedTicket = ticketRepository.save(ticket);

                // 5. Record Initial History
                HistorialEstado historial = new HistorialEstado();
                historial.setTicket(savedTicket);
                historial.setEstado(estadoAbierto);
                historial.setEstadoAnterior(null);
                historial.setEstadoNuevo(estadoAbierto);
                historial.setUsuario(user);
                historial.setUsuarioBd(resolveDbUsername(user));
                historial.setObservacion("Ticket creado por el cliente");
                historialEstadoRepository.save(historial);

                // ── AUDITORÍA: Creación de Ticket ────────────────────────────────────
                auditService.registrarEventoContextual(
                                AuditModulo.TICKETS,
                                "soporte", "ticket",
                                savedTicket.getIdTicket(),
                                AuditAccion.INSERT,
                                "Creación inicial de ticket por el cliente",
                                null,
                                java.util.Map.of("id_cliente", cliente.getIdCliente(), "asunto", ticket.getAsunto()));
                // ────────────────────────────────────────────────────────────────────

                return savedTicket;
        }

        @Transactional
        public ComentarioTicket addComment(Integer idTicket, User user, String text, Boolean esInterno) {
                Ticket ticket = getTicketById(idTicket);

                ComentarioTicket comentario = new ComentarioTicket();
                comentario.setTicket(ticket);
                comentario.setUsuario(user);
                comentario.setComentario(text);
                comentario.setContenido(text); // Added required field
                comentario.setEsInterno(esInterno != null ? esInterno : false);
                comentario.setVisibleParaCliente(esInterno == null || !esInterno); // Map to visible_para_cliente
                comentario.setEstadoItem(ticket.getEstadoItem()); // Added required field

                // Identify Empresa
                Integer idEmpresa = user.getIdEmpresa();

                // Fallback 1: If user has no company assigned, use the company of the ticket's
                // sucursal
                if (idEmpresa == null && ticket.getSucursal() != null && ticket.getSucursal().getEmpresa() != null) {
                        idEmpresa = ticket.getSucursal().getEmpresa().getId();
                }

                // Fallback 2: If still null, use the company of the ticket creator
                if (idEmpresa == null && ticket.getUsuarioCreador() != null) {
                        idEmpresa = ticket.getUsuarioCreador().getIdEmpresa();
                }

                if (idEmpresa == null) {
                        // Final Fallback: Get the first company in the system if any,
                        // as a comment MUST have a company associated in the current schema
                        List<Empresa> empresas = empresaRepository.findAll();
                        if (!empresas.isEmpty()) {
                                idEmpresa = empresas.get(0).getId();
                        } else {
                                throw new RuntimeException(
                                                "Error: No se pudo determinar la empresa para el comentario");
                        }
                }

                final Integer finalIdEmpresa = idEmpresa;

                // --- FIX: SET THE EMPRESA ENTITY ---
                Empresa empresa = empresaRepository.findById(finalIdEmpresa)
                                .orElseThrow(() -> new RuntimeException(
                                                "Error: Empresa no encontrada con ID: " + finalIdEmpresa));
                comentario.setEmpresa(empresa);
                // -----------------------------------

                ComentarioTicket savedComentario = comentarioTicketRepository.save(comentario);

                // ── AUDITORÍA: Creación de Comentario ────────────────────────────────
                String obsComentario = (esInterno != null && esInterno)
                                ? "Comentario interno agregado al ticket"
                                : "Comentario visible al cliente agregado al ticket";

                auditService.registrarEventoContextual(
                                AuditModulo.TICKETS,
                                "soporte", "comentario_ticket",
                                savedComentario.getIdComentario(),
                                AuditAccion.COMENTARIO,
                                obsComentario,
                                null,
                                java.util.Map.of(
                                                "id_ticket", idTicket,
                                                "es_interno", (esInterno != null && esInterno)));
                // ────────────────────────────────────────────────────────────────────

                return savedComentario;
        }

        @Transactional
        public Ticket updateTicketStatus(Integer idTicket, User user, String statusCode, String observation) {
                Ticket ticket = getTicketById(idTicket);
                CatalogoItem estadoAnterior = ticket.getEstadoItem();

                CatalogoItem estadoNuevo = catalogoItemRepository
                                .findByCatalogo_NombreAndCodigo("ESTADO_TICKET", statusCode)
                                .orElseThrow(() -> new RuntimeException(
                                                "Error: Status '" + statusCode + "' not found"));

                if (estadoAnterior.getId().equals(estadoNuevo.getId())) {
                        return ticket;
                }

                // Update ticket
                ticket.setEstadoItem(estadoNuevo);
                if (statusCode.equals("CERRADO") || statusCode.equals("RESUELTO")) {
                        ticket.setFechaCierre(java.time.LocalDateTime.now());
                } else {
                        ticket.setFechaCierre(null);
                }

                // Record history
                HistorialEstado historial = new HistorialEstado();
                historial.setTicket(ticket);
                historial.setEstado(estadoNuevo); // Current state
                historial.setEstadoAnterior(estadoAnterior);
                historial.setEstadoNuevo(estadoNuevo);
                historial.setUsuario(user);
                historial.setUsuarioBd(resolveDbUsername(user));
                historial.setObservacion(observation);
                historialEstadoRepository.save(historial);

                // ── AUDITORÍA: Cambio de Estado y Posible Cierre ─────────────────────
                boolean esCierre = "CERRADO".equals(statusCode) || "RESUELTO".equals(statusCode);

                if (esCierre) {
                        auditService.registrarEvento(
                                        AuditModulo.TICKETS,
                                        "soporte", "ticket",
                                        ticket.getIdTicket(),
                                        AuditAccion.CAMBIO_ESTADO,
                                        "Cierre o resolución de ticket. Nota: " + observation,
                                        java.util.Map.of("estado_anterior", estadoAnterior.getCodigo()),
                                        java.util.Map.of("estado_final", statusCode),
                                        user.getId());
                } else {
                        auditService.registrarCambioEstadoTicket(
                                        ticket.getIdTicket(),
                                        estadoAnterior.getId(),
                                        estadoNuevo.getId(),
                                        resolveDbUsername(user),
                                        user.getId());
                }
                // ────────────────────────────────────────────────────────────────────

                // Notificar al Creador del Ticket (Web Interactiva)
                String rutaUsuario = "/home/user/ticket/" + ticket.getIdTicket();

                notificacionServiceApp.crearNotificacionWeb(
                                ticket.getUsuarioCreador(),
                                "Actualización del Ticket #" + ticket.getIdTicket(),
                                "El estado de su ticket ha cambiado a: " + estadoNuevo.getNombre(),
                                rutaUsuario,
                                ticket);

                // --- NUEVA NOTIFICACIÓN POR CORREO (ESTADO) ---
                User usuarioReportante = ticket.getUsuarioCreador();
                if (usuarioReportante != null) {
                        String emailDestino = getEmailSeguro(usuarioReportante);
                        if (emailDestino != null) {
                                String urlFront = "http://localhost:4200/home/user/ticket/" + ticket.getIdTicket();
                                String cuerpoMail;
                                String literalEstado = estadoNuevo.getNombre();

                                if ("REQUIERE_VISITA".equals(statusCode)) {
                                        cuerpoMail = mailTemplateService.formatVisitRequired(
                                                        getNombreCompleto(usuarioReportante),
                                                        ticket.getIdTicket(),
                                                        ticket.getAsunto(),
                                                        observation,
                                                        getNombreCompleto(user),
                                                        urlFront);
                                } else {
                                        cuerpoMail = mailTemplateService.formatTicketStatusUpdate(
                                                        getNombreCompleto(usuarioReportante),
                                                        ticket.getIdTicket(),
                                                        ticket.getAsunto(),
                                                        literalEstado,
                                                        observation,
                                                        getNombreCompleto(user),
                                                        urlFront);
                                }

                                notificacionServiceApp.encolarCorreo(
                                                ticket,
                                                emailDestino,
                                                "Ticket #" + ticket.getIdTicket() + " - " + literalEstado,
                                                cuerpoMail);
                        }
                }

                return ticketRepository.save(ticket);
        }

        @Transactional
        public Ticket rateTicket(Integer idTicket, User user, Integer puntuacion, String comentario) {
                Ticket ticket = getTicketById(idTicket);

                // 1. Verify the caller is the ticket owner
                if (ticket.getUsuarioCreador() == null ||
                                !ticket.getUsuarioCreador().getId().equals(user.getId())) {
                        throw new ResponseStatusException(HttpStatus.FORBIDDEN,
                                        "Error: Solo el usuario que creó el ticket puede calificarlo");
                }

                // 2. Verify the ticket is closed or resolved
                String statusCode = ticket.getEstadoItem() != null ? ticket.getEstadoItem().getCodigo() : "";
                if (!"CERRADO".equals(statusCode) && !"RESUELTO".equals(statusCode)) {
                        throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                                        "Error: Solo se puede calificar un ticket con estado CERRADO o RESUELTO");
                }

                // 3. Prevent duplicate ratings
                if (ticket.getCalificacionSatisfaccion() != null) {
                        throw new ResponseStatusException(HttpStatus.CONFLICT,
                                        "Error: Este ticket ya fue calificado");
                }

                // 4. Save the rating
                ticket.setCalificacionSatisfaccion(puntuacion);
                ticket.setComentarioCalificacion(comentario);

                Ticket savedTicket = ticketRepository.save(ticket);

                // ── AUDITORÍA: Calificación de Servicio ──────────────────────────────
                auditService.registrarEvento(
                                AuditModulo.TICKETS,
                                "soporte", "ticket",
                                savedTicket.getIdTicket(),
                                AuditAccion.CALIFICACION,
                                "Cliente registró calificación de satisfacción",
                                java.util.Map.of(
                                                "puntuacion", "sin calificar",
                                                "comentario", "n/a"),
                                java.util.Map.of(
                                                "puntuacion", puntuacion,
                                                "comentario", comentario != null ? comentario : ""),
                                user.getId());
                // ────────────────────────────────────────────────────────────────────

                return savedTicket;
        }

        public Double getAvgRatingByTecnico(User tecnico) {
                return ticketRepository.findAvgRatingByTecnico(tecnico);
        }

        public Long countRatedTicketsByTecnico(User tecnico) {
                return ticketRepository.countRatedTicketsByTecnico(tecnico);
        }

        public Long countTicketsByTecnico(User tecnico) {
                return ticketRepository.countTicketsByTecnico(tecnico);
        }

        // ─── Informe Técnico ──────────────────────────────────────────────────────

        @Transactional
        public InformeTrabajoTecnico submitInformeTecnico(Integer idTicket, User tecnico,
                        InformeTrabajoTecnicoRequest req) {

                Ticket ticket = getTicketById(idTicket);

                // 1. Verify ticket is in EN_PROCESO state
                String estadoActual = ticket.getEstadoItem() != null ? ticket.getEstadoItem().getCodigo() : "";
                if (!"EN_PROCESO".equals(estadoActual)) {
                        throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                                        "El ticket debe estar en estado EN_PROCESO para registrar el informe técnico.");
                }

                // 2. Verify this technician is the assigned one
                if (ticket.getUsuarioAsignado() == null ||
                                !ticket.getUsuarioAsignado().getId().equals(tecnico.getId())) {
                        // Allow ADMIN_MASTER to submit informe regardless
                        boolean isAdmin = tecnico.getRole() != null &&
                                        ("ADMIN_MASTER".equals(tecnico.getRole().getCodigo()));
                        if (!isAdmin) {
                                throw new ResponseStatusException(HttpStatus.FORBIDDEN,
                                                "Solo el técnico asignado puede registrar el informe de este ticket.");
                        }
                }

                // 3. Check if an informe already exists for this ticket
                Optional<InformeTrabajoTecnico> existente = informeTrabajoTecnicoRepository
                                .findByTicket_IdTicket(idTicket);
                if (existente.isPresent()) {
                        throw new ResponseStatusException(HttpStatus.CONFLICT,
                                        "Ya existe un informe técnico registrado para este ticket.");
                }

                // 4. Validate required fields based on resultado
                String resultado = req.getResultado();
                if (resultado == null || (!"RESUELTO".equals(resultado) && !"NO_RESUELTO".equals(resultado))) {
                        throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                                        "El campo 'resultado' debe ser RESUELTO o NO_RESUELTO.");
                }

                // 5. Build and save informe
                InformeTrabajoTecnico informe = InformeTrabajoTecnico.builder()
                                .ticket(ticket)
                                .tecnico(tecnico)
                                .resultado(resultado)
                                .implementosUsados(req.getImplementosUsados())
                                .problemasEncontrados(req.getProblemasEncontrados())
                                .solucionAplicada(req.getSolucionAplicada())
                                .pruebasRealizadas(req.getPruebasRealizadas())
                                .motivoNoResolucion(req.getMotivoNoResolucion())
                                .comentarioTecnico(req.getComentarioTecnico())
                                .urlAdjunto(req.getUrlAdjunto())
                                .tiempoTrabajoMinutos(req.getTiempoTrabajoMinutos())
                                .build();

                InformeTrabajoTecnico savedInforme = informeTrabajoTecnicoRepository.save(informe);

                // 5.b Save Inventory Usage
                if (req.getInventarioItems() != null) {
                        for (InformeTrabajoTecnicoRequest.ItemUsadoRequest itemReq : req.getInventarioItems()) {
                                if (itemReq.getIdItemInventario() != null && itemReq.getCantidad() != null
                                                && itemReq.getCantidad() > 0) {
                                        Inventario inv = inventarioRepository.findById(itemReq.getIdItemInventario())
                                                        .orElseThrow(() -> new ResponseStatusException(
                                                                        HttpStatus.NOT_FOUND,
                                                                        "Item de inventario no encontrado: " + itemReq
                                                                                        .getIdItemInventario()));

                                        // Validation before saving
                                        if (inv.getStockActual() < itemReq.getCantidad()) {
                                                throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                                                                "Stock insuficiente para el ítem: " + inv.getNombre()
                                                                                + ". Disponible: "
                                                                                + inv.getStockActual());
                                        }

                                        // Stock manual deduction removed. Handled by BD Trigger.

                                        InventarioUsadoTicket uso = InventarioUsadoTicket.builder()
                                                        .ticket(ticket)
                                                        .inventario(inv)
                                                        .cantidad(itemReq.getCantidad())
                                                        .tecnico(tecnico)
                                                        .fechaRegistro(LocalDateTime.now())
                                                        .build();
                                        inventarioUsadoTicketRepository.save(uso);
                                }
                        }
                }

                // 6. Update ticket status based on resultado
                String nuevoEstadoCodigo;
                if ("RESUELTO".equals(resultado)) {
                        nuevoEstadoCodigo = "RESUELTO";
                } else {
                        // NO_RESUELTO: re-open ticket to ABIERTO for new assignment
                        // Check if NO_RESUELTO catalog item exists, fallback to ABIERTO
                        boolean noResueltoExists = catalogoItemRepository
                                        .findByCatalogo_NombreAndCodigo("ESTADO_TICKET", "NO_RESUELTO")
                                        .isPresent();
                        nuevoEstadoCodigo = noResueltoExists ? "NO_RESUELTO" : "ABIERTO";
                }

                updateTicketStatus(idTicket, tecnico, nuevoEstadoCodigo,
                                "NO_RESUELTO".equals(resultado)
                                                ? "Técnico no pudo resolver: " + (req.getMotivoNoResolucion() != null
                                                                ? req.getMotivoNoResolucion()
                                                                : "")
                                                : "Informe técnico registrado. Ticket resuelto.");

                // 7. Audit
                auditService.registrarEventoContextual(
                                AuditModulo.TICKETS,
                                "soporte", "informe_trabajo_tecnico",
                                savedInforme.getIdInforme(),
                                AuditAccion.INSERT,
                                "Técnico registró informe de trabajo. Resultado: " + resultado,
                                null,
                                java.util.Map.of(
                                                "id_ticket", idTicket,
                                                "resultado", resultado));

                return savedInforme;
        }

        @Transactional
        public java.util.Map<String, java.util.Map<String, Long>> getOptionFrequencies() {
                java.util.Map<String, java.util.Map<String, Long>> frequencies = new java.util.HashMap<>();

                frequencies.put("implementos",
                                countFrequencies(informeTrabajoTecnicoRepository.findAllResolvedImplementos()));
                frequencies.put("problemas",
                                countFrequencies(informeTrabajoTecnicoRepository.findAllResolvedProblemas()));
                frequencies.put("soluciones",
                                countFrequencies(informeTrabajoTecnicoRepository.findAllResolvedSoluciones()));

                return frequencies;
        }

        private java.util.Map<String, Long> countFrequencies(List<String> rawData) {
                java.util.Map<String, Long> counts = new java.util.HashMap<>();
                if (rawData == null)
                        return counts;

                for (String line : rawData) {
                        if (line == null)
                                continue;
                        String[] parts = line.split(",");
                        for (String p : parts) {
                                String clean = p.trim();
                                if (!clean.isEmpty()) {
                                        counts.put(clean, counts.getOrDefault(clean, 0L) + 1);
                                }
                        }
                }
                return counts;
        }

        @Transactional
        public Optional<InformeTrabajoTecnico> getInformeTecnico(Integer idTicket) {
                return informeTrabajoTecnicoRepository.findByTicket_IdTicket(idTicket);
        }

        public List<InventarioUsadoTicket> getInventarioUsado(Integer idTicket) {
                return inventarioUsadoTicketRepository.findByTicket_IdTicket(idTicket);
        }

        @Autowired
        private PdfReporteService pdfReporteService;

        @Transactional
        public ByteArrayInputStream generateTicketPdf(Integer idTicket) {
                Ticket ticket = getTicketById(idTicket);
                InformeTrabajoTecnico informe = getInformeTecnico(idTicket).orElse(null);
                List<HistorialEstado> historial = historialEstadoRepository
                                .findByTicket_IdTicketOrderByFechaCambioDesc(idTicket);
                List<ComentarioTicket> comentarios = comentarioTicketRepository
                                .findByTicket_IdTicketOrderByFechaCreacionDesc(idTicket);
                List<InventarioUsadoTicket> inventarioUsado = inventarioUsadoTicketRepository
                                .findByTicket_IdTicket(idTicket);

                return pdfReporteService.generateTicketDetailReport(ticket, informe, historial, comentarios,
                                inventarioUsado);
        }

        /**
         * Resuelve el nombre físico del rol PostgreSQL en la base de datos (ej.
         * emp_0503360398_7).
         * Si el usuario no tiene un rol físico (ej. clientes), devuelve el username de
         * la app.
         */
        private String resolveDbUsername(User user) {
                if (user == null || user.getId() == null)
                        return null;
                List<UsuarioBd> dbs = usuarioBdRepository.findByUser_Id(user.getId());
                if (dbs != null && !dbs.isEmpty()) {
                        return dbs.get(0).getNombre();
                }
                return user.getUsername();
        }

        private String getNombreCompleto(User user) {
                if (user == null)
                        return "Usuario desconocido";
                if (user.getPersona() != null) {
                        String nombre = user.getPersona().getNombre() != null ? user.getPersona().getNombre() : "";
                        String apellido = user.getPersona().getApellido() != null ? user.getPersona().getApellido()
                                        : "";
                        String completo = (nombre + " " + apellido).trim();
                        return completo.isEmpty() ? user.getUsername() : completo;
                }
                return user.getUsername();
        }

        private String getEmailSeguro(User user) {
                if (user != null && user.getPersona() != null) {
                        return user.getPersona().getCorreo();
                }
                return null;
        }

        public List<Ticket> getTicketsPendingVisit() {
                return ticketRepository.findTicketsPendingVisit();
        }
}
