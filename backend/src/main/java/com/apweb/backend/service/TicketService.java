package com.apweb.backend.service;

import com.apweb.backend.model.*;
import com.apweb.backend.payload.request.InformeTrabajoTecnicoRequest;
import com.apweb.backend.payload.request.TicketRequest;
import com.apweb.backend.repository.*;
import com.apweb.backend.services.notificaciones.NotificacionServiceApp;
import com.apweb.backend.services.notificaciones.MailTemplateService;
import com.apweb.backend.dto.TechnicianDTO;
import com.apweb.backend.dto.DocumentoEmpleadoDTO;
import java.io.ByteArrayInputStream;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.time.LocalDateTime;
import com.apweb.backend.util.AuditAccion;
import com.apweb.backend.util.AuditModulo;

@Service
public class TicketService {

        @Autowired
        private TicketRepository ticketRepository;

        @Autowired
        private EmpleadoRepository empleadoRepository;

        @Autowired
        private DocumentoEmpleadoRepository documentoEmpleadoRepository;

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

        @Transactional(readOnly = true)
        public List<Ticket> getAllTickets() {
                List<Ticket> tickets = ticketRepository.findAllWithAssociations();
                tickets.forEach(this::loadTicketDeep);
                return tickets;
        }

        @Transactional(readOnly = true)
        public List<Ticket> getTicketsByUser(User user) {
                List<Ticket> tickets = ticketRepository.findByUsuarioCreador(user);
                tickets.forEach(this::loadTicketDeep);
                return tickets;
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
                                .orElseThrow(() -> new RuntimeException("Error: Ticket no encontrado con ID: " + id));
                loadTicketDeep(ticket);
                return ticket;
        }

        @Transactional(readOnly = true)
        public long getActiveTicketsCountForUser(User user) {
                java.util.Set<Integer> ticketIds = new java.util.HashSet<>();
                
                // Primary assignments
                ticketRepository.findByUsuarioAsignado(user).forEach(t -> {
                    if (t != null && t.getEstadoItem() != null && !"CERRADO".equals(t.getEstadoItem().getCodigo())) {
                        ticketIds.add(t.getIdTicket());
                    }
                });
                
                // Group assignments
                asignacionRepository.findByUsuarioAndActivoTrue(user).forEach(a -> {
                    if (a.getTicket() != null && a.getTicket().getEstadoItem() != null && !"CERRADO".equals(a.getTicket().getEstadoItem().getCodigo())) {
                        ticketIds.add(a.getTicket().getIdTicket());
                    }
                });
                
                return ticketIds.size();
        }

        @Transactional(readOnly = true)
        public List<Ticket> getTicketsByAssignedUser(User user) {
                // Use a map to deduplicate by ID safely
                java.util.Map<Integer, Ticket> ticketMap = new java.util.HashMap<>();
                
                // Primary assignments
                ticketRepository.findByUsuarioAsignadoWithAssociations(user).forEach(t -> {
                    if (t != null) ticketMap.put(t.getIdTicket(), t);
                });
                
                // Group assignments
                asignacionRepository.findByUsuarioAndActivoTrueWithAssociations(user).forEach(a -> {
                    if (a.getTicket() != null) {
                        ticketMap.put(a.getTicket().getIdTicket(), a.getTicket());
                    }
                });
                
                List<Ticket> result = new java.util.ArrayList<>(ticketMap.values());
                
                // Deep loading to prevent LazyInitializationException during serialization
                for (Ticket t : result) {
                    loadTicketDeep(t);
                }
                
                return result;
        }

        private void loadTicketDeep(Ticket t) {
            if (t == null) return;
            
            // Basic associations
            if (t.getEstadoItem() != null) t.getEstadoItem().getNombre();
            if (t.getCategoriaItem() != null) t.getCategoriaItem().getNombre();
            if (t.getPrioridadItem() != null) t.getPrioridadItem().getNombre();
            if (t.getServicio() != null) t.getServicio().getNombre();
            if (t.getSucursal() != null) {
                t.getSucursal().getNombre();
                if (t.getSucursal().getEmpresa() != null) t.getSucursal().getEmpresa().getNombreComercial();
            }
            
            // Cliente & Persona
            if (t.getCliente() != null) {
                if (t.getCliente().getPersona() != null) {
                    t.getCliente().getPersona().getNombre();
                    if (t.getCliente().getPersona().getCanton() != null) t.getCliente().getPersona().getCanton().getNombre();
                }
            }
            
            // Users and their Personas
            if (t.getUsuarioCreador() != null) {
                t.getUsuarioCreador().getUsername();
                if (t.getUsuarioCreador().getPersona() != null) {
                    t.getUsuarioCreador().getPersona().getNombre();
                    if (t.getUsuarioCreador().getPersona().getCanton() != null) t.getUsuarioCreador().getPersona().getCanton().getNombre();
                }
            }
            if (t.getUsuarioAsignado() != null) {
                t.getUsuarioAsignado().getUsername();
                if (t.getUsuarioAsignado().getPersona() != null) {
                    t.getUsuarioAsignado().getPersona().getNombre();
                    if (t.getUsuarioAsignado().getPersona().getCanton() != null) t.getUsuarioAsignado().getPersona().getCanton().getNombre();
                }
            }

            // Collections (Managed references are serialized by Jackson)
            // Using toArray to avoid ConcurrentModification if Hibernate triggers session activity
            if (t.getHistorialEstados() != null) {
                Object[] history = t.getHistorialEstados().toArray();
                for (Object o : history) {
                    HistorialEstado h = (HistorialEstado) o;
                    if (h.getEstado() != null) h.getEstado().getNombre();
                    if (h.getEstadoNuevo() != null) h.getEstadoNuevo().getNombre();
                    if (h.getEstadoAnterior() != null) h.getEstadoAnterior().getNombre();
                    if (h.getUsuario() != null) {
                        h.getUsuario().getUsername();
                        if (h.getUsuario().getPersona() != null) h.getUsuario().getPersona().getNombre();
                    }
                }
            }
            
            if (t.getComentarios() != null) {
                Object[] comments = t.getComentarios().toArray();
                for (Object o : comments) {
                    ComentarioTicket c = (ComentarioTicket) o;
                    if (c.getUsuario() != null) {
                        c.getUsuario().getUsername();
                        if (c.getUsuario().getPersona() != null) c.getUsuario().getPersona().getNombre();
                    }
                    if (c.getEstadoItem() != null) c.getEstadoItem().getNombre();
                    if (c.getEmpresa() != null) c.getEmpresa().getNombreComercial();
                }
            }
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

                // Deactivate any currently active assignments for this ticket
                List<Asignacion> asignacionesActivas = asignacionRepository.findByTicket(ticket);
                for (Asignacion a : asignacionesActivas) {
                        if (a.getActivo()) {
                                a.setActivo(false);
                                asignacionRepository.save(a);
                        }
                }
                asignacionRepository.flush(); // Ensure the deactivation is completed before new insert

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
                boolean isReassignment = previousAssignee != null;
                String typePrefix = isReassignment ? "REASIGNACIÓN: " : "";

                // 1. Notificar al Técnico (Solo Web + Interactiva)
                String rutaTecnico = "/home/user/ticket/" + savedTicket.getIdTicket();
                notificacionServiceApp.crearNotificacionWeb(
                                technician,
                                typePrefix + "Ticket Assigned #" + savedTicket.getIdTicket(),
                                (isReassignment ? "Se le ha reasignado el ticket: " : "Se le ha asignado el ticket: ") + savedTicket.getAsunto(),
                                rutaTecnico,
                                savedTicket);

                // 2. Notificar al Usuario Reportante (Web Interactiva + Correo)
                User usuarioReportante = savedTicket.getUsuarioCreador();
                if (usuarioReportante != null) {
                        String rutaUsuario = "/home/user/ticket/" + savedTicket.getIdTicket();
                        String nombreTecnico = getNombreCompleto(technician);
                        
                        String tituloWeb = isReassignment ? "Su ticket #" + savedTicket.getIdTicket() + " ha sido REASIGNADO" 
                                                         : "Su ticket #" + savedTicket.getIdTicket() + " ha sido asignado";
                        String msjWeb = isReassignment ? "Su ticket ha sido reasignado al técnico " + nombreTecnico 
                                                       : "Su ticket ahora está siendo atendido por " + nombreTecnico;

                        notificacionServiceApp.crearNotificacionWeb(
                                        usuarioReportante,
                                        tituloWeb,
                                        msjWeb,
                                        rutaUsuario,
                                        savedTicket);

                        // Encolar Correo
                        String emailDestino = getEmailSeguro(usuarioReportante);
                        if (emailDestino != null) {
                                String urlFront = "http://localhost:4200/home/user/ticket/" + savedTicket.getIdTicket();
                                String cuerpoMail = mailTemplateService.formatTicketAssignment(
                                                getNombreCompleto(usuarioReportante),
                                                savedTicket.getIdTicket(),
                                                savedTicket.getAsunto(),
                                                nombreTecnico,
                                                urlFront);

                                String subjectMail = isReassignment ? "Ticket #" + savedTicket.getIdTicket() + " - REASIGNADO" 
                                                                    : "Ticket #" + savedTicket.getIdTicket() + " - Técnico Asignado";

                                notificacionServiceApp.encolarCorreo(
                                                savedTicket,
                                                emailDestino,
                                                subjectMail,
                                                cuerpoMail);
                        }
                }

                return savedTicket;
        }

        @Transactional
        public List<Ticket> assignTicketMultiple(Integer idTicket, List<Integer> idUsers, User assigner,
                        String groupCode) {
                Ticket ticket = getTicketById(idTicket);
                if (idUsers == null || idUsers.isEmpty()) {
                        throw new RuntimeException("Error: No users provided for assignment");
                }

                CatalogoItem estadoAnterior = ticket.getEstadoItem();
                CatalogoItem estadoAsignado = catalogoItemRepository
                                .findByCatalogo_NombreAndCodigo("ESTADO_TICKET", "ASIGNADO")
                                .orElseThrow(() -> new RuntimeException("Error: Status 'ASIGNADO' not found"));

                // Update ticket to ASIGNADO and set primary assignee (first one)
                User firstTechnician = userRepository.findById(idUsers.get(0))
                                .orElseThrow(() -> new RuntimeException("Error: User not found with ID: " + idUsers.get(0)));
                ticket.setUsuarioAsignado(firstTechnician);
                ticket.setEstadoItem(estadoAsignado);
                ticketRepository.save(ticket);

                // Create multiple assignment records
                for (Integer userId : idUsers) {
                        User technician = userRepository.findById(userId)
                                        .orElseThrow(() -> new RuntimeException("Error: User not found with ID: " + userId));

                        Asignacion asignacion = new Asignacion();
                        asignacion.setTicket(ticket);
                        asignacion.setUsuario(technician);
                        asignacion.setActivo(true);
                        asignacionRepository.save(asignacion);

                        // Record history for each
                        HistorialEstado historial = new HistorialEstado();
                        historial.setTicket(ticket);
                        historial.setEstado(estadoAsignado);
                        historial.setEstadoAnterior(estadoAnterior);
                        historial.setEstadoNuevo(estadoAsignado);
                        historial.setUsuario(assigner);
                        historial.setUsuarioBd(resolveDbUsername(assigner));
                        historial.setObservacion("Ticket asignado a " + technician.getUsername()
                                        + (groupCode != null ? " (Grupo: " + groupCode + ")" : ""));
                        historialEstadoRepository.save(historial);

                        // Audit
                        auditService.registrarEvento(
                                        AuditModulo.TICKETS,
                                        "soporte", "ticket",
                                        ticket.getIdTicket(),
                                        AuditAccion.UPDATE,
                                        "Ticket asignado al técnico: " + technician.getUsername()
                                                        + (groupCode != null ? " como parte del grupo " + groupCode : ""),
                                        null,
                                        java.util.Map.of("idUsuarioAsignado", technician.getId()),
                                        assigner.getId());

                        // Notification
                        notificacionServiceApp.crearNotificacionWeb(
                                        technician,
                                        "Nuevo Ticket Asignado: #" + ticket.getIdTicket(),
                                        "Se le ha asignado el ticket: " + ticket.getAsunto()
                                                        + (groupCode != null ? " (Grupo: " + groupCode + ")" : ""),
                                        "/home/user/ticket/" + ticket.getIdTicket(),
                                        ticket);
                }

                return List.of(ticket);
        }

        @Transactional
        public Ticket reassignTicket(Integer idTicket, Integer idUser, User reassigner, String notaReasignacion) {
                Ticket ticket = getTicketById(idTicket);

                // Security check: Only ADMIN_MASTER can reassign
                if (reassigner.getRole() == null || !"ADMIN_MASTER".equals(reassigner.getRole().getCodigo())) {
                        throw new ResponseStatusException(HttpStatus.FORBIDDEN,
                                        "Solo el Administrador Master puede reasignar un ticket reprogramado.");
                }

                // Allowed states for reassignment: ASIGNADO, EN_PROCESO, REPROGRAMADA, REQUIERE_VISITA
                String currentStatus = ticket.getEstadoItem() != null ? ticket.getEstadoItem().getCodigo() : "";
                boolean canReassignStatus = "ASIGNADO".equals(currentStatus) || 
                                           "EN_PROCESO".equals(currentStatus) || 
                                           "REPROGRAMADA".equals(currentStatus) ||
                                           "REQUIERE_VISITA".equals(currentStatus);
                
                if (!canReassignStatus) {
                        throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                                        "El ticket no se encuentra en un estado que permita reasignación.");
                }

                // Ensure note is provided
                String finalNote = (notaReasignacion != null && !notaReasignacion.trim().isEmpty()) 
                    ? notaReasignacion.trim() 
                    : "Reasignación sin nota específica";
                // Reassign using the common logic
                Ticket updatedTicket = assignTicket(idTicket, idUser, reassigner);
                
                // Add commentary with the reassign reason
                addComment(idTicket, reassigner, "NOTA DE REASIGNACIÓN: " + finalNote, true);

                return updatedTicket;
        }

        @Transactional(readOnly = true)
        public java.util.List<TechnicianDTO> getAllTechniciansDetailed() {
                java.util.List<String> roleAllowed = java.util.Arrays.asList("TECNICO", "ADMIN_TECNICOS", "ADMIN_MASTER");
                java.util.List<Empleado> allEmps = empleadoRepository.findAllWithAllAssociations();
                
                if (allEmps == null) return new java.util.ArrayList<>();

                java.util.List<TechnicianDTO> result = new java.util.ArrayList<>();
                for (Empleado e : allEmps) {
                    try {
                        if (e == null) continue;
                        Persona persona = e.getPersona();
                        User user = (persona != null) ? persona.getUser() : null;
                        
                        // Filter by role manually to be safe against JOIN FETCH complexities in WHERE
                        if (user == null || user.getRole() == null || !roleAllowed.contains(user.getRole().getCodigo())) {
                            continue;
                        }

                        Long ticketsAsignadosTotal = countTicketsByTecnico(user);
                        if (ticketsAsignadosTotal == null) ticketsAsignadosTotal = 0L;

                        Long ticketsActivosEncontrados = getActiveTicketsCountForUser(user);
                        
                        Double promedioCalificacion = getAvgRatingByTecnico(user);

                        // Calculate derived values
                        Long ticketsResueltos = countRatedTicketsByTecnico(user);
                        if (ticketsResueltos == null) ticketsResueltos = 0L;
                        
                        double porcentaje = ticketsAsignadosTotal > 0 ? ((double) ticketsResueltos / ticketsAsignadosTotal) * 100.0 : 0.0;
                        
                        String nivel = "Básico";
                        if (promedioCalificacion != null) {
                            if (promedioCalificacion >= 4.0) nivel = "Alto";
                            else if (promedioCalificacion >= 3.0) nivel = "Medio";
                        }
                        
                        String estadoUser = (user.getEstado() != null) ? user.getEstado().getNombre() : "Activo";
                        String especialidadArea = (e.getArea() != null) ? e.getArea().getNombre() : "Soporte General";
                        
                        String promedioStr = (promedioCalificacion != null) ? String.valueOf(Math.round(promedioCalificacion * 10.0) / 10.0) : "N/A";
                        String historial = "Promedio: " + promedioStr + " / Tickets Totales: " + ticketsAsignadosTotal;

                        result.add(TechnicianDTO.builder()
                                .userId(user.getId())
                                .empleadoId(e.getIdEmpleado())
                                .username(user.getUsername())
                                .nombre(persona.getNombre() != null ? persona.getNombre() : "N/A")
                                .apellido(persona.getApellido() != null ? persona.getApellido() : "N/A")
                                .cedula(persona.getCedula() != null ? persona.getCedula() : "N/A")
                                .correo(persona.getCorreo() != null ? persona.getCorreo() : "N/A")
                                .celular(persona.getCelular() != null ? persona.getCelular() : "N/A")
                                .cargo(e.getCargo() != null ? e.getCargo().getNombre() : "Sin Cargo")
                                .area(e.getArea() != null ? e.getArea().getNombre() : "Sin Área")
                                .tipoContrato(e.getTipoContrato() != null ? e.getTipoContrato().getNombre() : "Desconocido")
                                .fechaIngreso(e.getFechaIngreso())
                                .estado(estadoUser)
                                .ticketsAsignados(ticketsAsignadosTotal)
                                .ticketsResueltosHoy(0L)
                                .porcentajeResolucion(Math.round(porcentaje * 10.0) / 10.0)
                                .nivelRendimiento(nivel)
                                .ticketsActivos(ticketsActivosEncontrados)
                                .especialidad(especialidadArea)
                                .historialResumido(historial)
                                .build());
                    } catch (Exception ex) {
                        // Skip problematic records instead of failing the whole list
                        continue;
                    }
                }
                return result;
        }


        @Transactional(readOnly = true)
        public List<DocumentoEmpleadoDTO> getTechnicianDocuments(Integer userId) {
                Empleado empleado = empleadoRepository.findByPersona_User_Id(userId)
                                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND,
                                                "Empleado no encontrado para el usuario."));

                List<DocumentoEmpleado> documents = documentoEmpleadoRepository.findByEmpleado_IdEmpleado(empleado.getIdEmpleado());
                return documents.stream().map(d -> DocumentoEmpleadoDTO.builder()
                                .idDocumento(d.getIdDocumento())
                                .numeroDocumento(d.getNumeroDocumento())
                                .rutaArchivo(d.getRutaArchivo())
                                .descripcion(d.getDescripcion())
                                .fechaSubida(d.getFechaSubida())
                                .idTipoDocumento(d.getTipoDocumento() != null ? d.getTipoDocumento().getId() : null)
                                .codigoTipoDocumento(d.getTipoDocumento() != null ? d.getTipoDocumento().getCodigo() : null)
                                .idEstado(d.getEstado() != null ? d.getEstado().getId() : null)
                                .nombreEstado(d.getEstado() != null ? d.getEstado().getNombre() : null)
                                .build()).collect(java.util.stream.Collectors.toList());
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
                                .orElse(null);

                // Handling for specific REPROGRAMADA case as per user requirement (id_item =
                // 42)
                if (estadoNuevo == null && "REPROGRAMADA".equals(statusCode)) {
                        estadoNuevo = catalogoItemRepository.findById(42).orElse(null);
                }

                // Global fallback search by code if not found yet
                if (estadoNuevo == null) {
                        estadoNuevo = catalogoItemRepository.findByCodigo(statusCode).orElse(null);
                }

                if (estadoNuevo == null) {
                        throw new RuntimeException("Error: Status '" + statusCode + "' not found");
                }

                // Logic: Only admin can change status if it is currently REPROGRAMADA
                boolean isAdmin = user.getRole() != null &&
                                ("ADMIN_MASTER".equals(user.getRole().getCodigo()) ||
                                                "ADMIN".equals(user.getRole().getCodigo()) ||
                                                "ADMIN_TECNICOS".equals(user.getRole().getCodigo()));

                if ("REPROGRAMADA".equals(estadoAnterior.getCodigo())) {
                        if (!isAdmin) {
                                throw new ResponseStatusException(HttpStatus.FORBIDDEN,
                                                "Solo un administrador puede permitir continuar un ticket despuès de ser REPROGRAMADA.");
                        }
                }

                // Logic: ONLY Admin can close tickets (CERRADO)
                if ("CERRADO".equals(statusCode)) {
                        boolean isMutualAgreement = ticket.getConfirmacionTecnico() && ticket.getConfirmacionCliente();
                        if (!isAdmin && !isMutualAgreement) {
                                throw new ResponseStatusException(HttpStatus.FORBIDDEN,
                                                "Solo un administrador puede CERRAR oficialmente un ticket, a menos que haya un acuerdo mutuo.");
                        }
                }

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
        public Ticket confirmClosure(Integer idTicket, User user) {
                Ticket ticket = getTicketById(idTicket);

                boolean isTechnician = ticket.getUsuarioAsignado() != null
                                && ticket.getUsuarioAsignado().getId().equals(user.getId());
                boolean isClient = ticket.getUsuarioCreador() != null
                                && ticket.getUsuarioCreador().getId().equals(user.getId());
                boolean isAdmin = user.getRole() != null &&
                                ("ADMIN_MASTER".equals(user.getRole().getCodigo()) ||
                                                "ADMIN".equals(user.getRole().getCodigo()) ||
                                                "ADMIN_TECNICOS".equals(user.getRole().getCodigo()));

                if (!isTechnician && !isClient && !isAdmin) {
                        throw new ResponseStatusException(HttpStatus.FORBIDDEN,
                                        "Solo el técnico asignado, el cliente o un administrador pueden confirmar el cierre.");
                }

                if (isTechnician || isAdmin) {
                        ticket.setConfirmacionTecnico(true);
                        addComment(idTicket, user, "El técnico/administrador ha confirmado el cierre del ticket.", true);
                }

                if (isClient) {
                        ticket.setConfirmacionCliente(true);
                        addComment(idTicket, user, "El cliente ha solicitado/confirmado el cierre del ticket.", false);
                }

                if (ticket.getConfirmacionTecnico() && ticket.getConfirmacionCliente()) {
                        return updateTicketStatus(idTicket, user, "CERRADO", "Ticket cerrado por acuerdo mutuo.");
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

                // 1. Verify ticket is in EN_PROCESO or ASIGNADO state
                String estadoActual = ticket.getEstadoItem() != null ? ticket.getEstadoItem().getCodigo() : "";
                if (!"EN_PROCESO".equals(estadoActual) && !"ASIGNADO".equals(estadoActual)) {
                        throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                                        "El ticket debe estar en estado ASIGNADO o EN_PROCESO para registrar el informe técnico.");
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

                // 3. Check for existing informe (Allow multiple but handle the current one)
                // We remove the hard-blocking search to allow new reports if it's a new assignment attempt
                // Optional<InformeTrabajoTecnico> existente = ...

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
                if ("RESUELTO".equals(resultado)) {
                        updateTicketStatus(idTicket, tecnico, "RESUELTO",
                                        "Ya apliqué la solución, por favor valida si funciona correctamente.");
                } else {
                        // NO_RESUELTO: updateTicketStatus will now find REPROGRAMADA correctly
                        // including specifically checking ID 42
                        updateTicketStatus(idTicket, tecnico, "REPROGRAMADA", 
                                        "Incidencia registrada como No Resuelta. Pasa a Reprogramación.");
                }

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

        public List<InformeTrabajoTecnico> getInformeTecnico(Integer idTicket) {
                return informeTrabajoTecnicoRepository.findByTicket_IdTicketOrderByIdInformeDesc(idTicket);
        }

        public List<InventarioUsadoTicket> getInventarioUsado(Integer idTicket) {
                return inventarioUsadoTicketRepository.findByTicket_IdTicket(idTicket);
        }

        @Autowired
        private PdfReporteService pdfReporteService;

        @Transactional
        public ByteArrayInputStream generateTicketPdf(Integer idTicket) {
                Ticket ticket = getTicketById(idTicket);

                // Requerimiento: Se puede descargar si está CERRADO, RESUELTO o REPROGRAMADA
                String code = ticket.getEstadoItem() != null ? ticket.getEstadoItem().getCodigo() : "";
                boolean canGenerate = "CERRADO".equals(code) || "RESUELTO".equals(code) || "REPROGRAMADA".equals(code);

                if (ticket.getIdTicket() != null && !canGenerate) {
                        throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                                        "El reporte PDF solo está disponible cuando el ticket ha sido resuelto o reprogramado.");
                }

                List<InformeTrabajoTecnico> informes = getInformeTecnico(idTicket);
                List<HistorialEstado> historial = historialEstadoRepository
                                .findByTicket_IdTicketOrderByFechaCambioDesc(idTicket);
                List<ComentarioTicket> comentarios = comentarioTicketRepository
                                .findByTicket_IdTicketOrderByFechaCreacionDesc(idTicket);
                List<InventarioUsadoTicket> inventarioUsado = inventarioUsadoTicketRepository
                                .findByTicket_IdTicket(idTicket);

                return pdfReporteService.generateTicketDetailReport(ticket, informes, historial, comentarios,
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
