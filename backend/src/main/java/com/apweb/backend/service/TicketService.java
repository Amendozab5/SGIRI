package com.apweb.backend.service;

import com.apweb.backend.model.*;
import com.apweb.backend.payload.request.TicketRequest;
import com.apweb.backend.repository.*;
import jakarta.transaction.Transactional;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

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
        private NotificationService notificationService;

        public List<Ticket> getAllTickets() {
                return ticketRepository.findAll();
        }

        public List<Ticket> getTicketsByUser(User user) {
                return ticketRepository.findByUsuarioCreador(user);
        }

        public Ticket getTicketById(Integer id) {
                return ticketRepository.findById(id)
                                .orElseThrow(() -> new RuntimeException("Error: Ticket not found with ID: " + id));
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
                historial.setUsuarioBd(assigner.getUsername());
                historial.setObservacion("Ticket asignado a " + technician.getUsername());
                historialEstadoRepository.save(historial);

                // Notify Technician
                notificationService.createNotification(assigner, technician, ticket,
                                "Nuevo Ticket Asignado: #" + ticket.getIdTicket(),
                                "Se le ha asignado el ticket: " + ticket.getAsunto());

                // Notify Client
                notificationService.createNotification(assigner, ticket.getUsuarioCreador(), ticket,
                                "Su ticket #" + ticket.getIdTicket() + " ha sido asignado",
                                "Su ticket ahora está siendo atendido por " + technician.getUsername());

                return ticketRepository.save(ticket);
        }

        @Transactional
        public Ticket createTicketForClient(User user, TicketRequest ticketRequest) {
                // 1. Identify Client
                Cliente cliente = clienteRepository.findByPersona_User(user)
                                .orElseThrow(() -> new RuntimeException(
                                                "Error: Logged user is not a registered client"));

                // 2. Fetch required entities
                Sucursal sucursal = sucursalRepository.findById(ticketRequest.getIdSucursal())
                                .orElseThrow(() -> new RuntimeException("Error: Sucursal not found"));

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
                historial.setUsuarioBd(user.getUsername());
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
                historial.setUsuarioBd(user.getUsername());
                historial.setObservacion(observation);
                historialEstadoRepository.save(historial);

                // Notify Creator
                notificationService.createNotification(user, ticket.getUsuarioCreador(), ticket,
                                "Actualización del Ticket #" + ticket.getIdTicket(),
                                "El estado de su ticket ha cambiado a: " + estadoNuevo.getNombre());

                return ticketRepository.save(ticket);
        }
}
