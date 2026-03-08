package com.apweb.backend.service;

import com.apweb.backend.model.*;
import com.apweb.backend.payload.request.TicketRequest;
import com.apweb.backend.repository.*;
import com.apweb.backend.services.notificaciones.NotificacionServiceApp;
import com.apweb.backend.services.notificaciones.MailTemplateService;
import jakarta.transaction.Transactional;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

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
                if (ticket.getCliente() != null) {
                        ticket.getCliente().getPersona().getNombre();
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

                Integer finalIdEmpresa = idEmpresa;
                Empresa empresa = empresaRepository.findById(finalIdEmpresa)
                                .orElseThrow(() -> new RuntimeException(
                                                "Error: Empresa not found with ID: " + finalIdEmpresa));
                comentario.setEmpresa(empresa);

                return comentarioTicketRepository.save(comentario);
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

                return ticketRepository.save(ticket);
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
}
