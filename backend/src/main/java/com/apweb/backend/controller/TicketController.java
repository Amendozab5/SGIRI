package com.apweb.backend.controller;

import com.apweb.backend.model.*;
import com.apweb.backend.payload.request.TicketRequest;
import com.apweb.backend.payload.response.MessageResponse;
import com.apweb.backend.repository.*;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Optional;

@CrossOrigin(origins = "*", maxAge = 3600)
@RestController
@RequestMapping("/api/tickets")
public class TicketController {

    @Autowired
    TicketRepository ticketRepository;

    @Autowired
    UserRepository userRepository;

    @Autowired
    CategoriaRepository categoriaRepository;

    @Autowired
    PrioridadRepository prioridadRepository;

    @Autowired
    CatalogoItemRepository catalogoItemRepository;

    @Autowired
    ServicioRepository servicioRepository;

    @Autowired
    SucursalRepository sucursalRepository;

    @Autowired
    SlaTicketRepository slaTicketRepository;

    @Autowired
    EmpresaRepository empresaRepository;

    @Autowired
    ClienteRepository clienteRepository;

    @Autowired
    EmpleadoRepository empleadoRepository;


    @PostMapping
    @PreAuthorize("hasRole('USER')")
        public ResponseEntity<?> createTicket( @Valid @RequestBody TicketRequest ticketRequest) {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String currentUserName = authentication.getName();

        User usuarioCreador = userRepository.findByUsername(currentUserName)
                .orElseThrow(() -> new RuntimeException("Error: User not found for " + currentUserName));

        Categoria categoria = categoriaRepository.findById(ticketRequest.getIdCategoria())
                .orElseThrow(() -> new RuntimeException("Error: Categoria not found for id: " + ticketRequest.getIdCategoria()));

        Prioridad prioridad = prioridadRepository.findById(ticketRequest.getIdPrioridad())
                .orElseThrow(() -> new RuntimeException("Error: Prioridad not found for id: " + ticketRequest.getIdPrioridad()));

        CatalogoItem estado = catalogoItemRepository.findById(ticketRequest.getIdEstado())
                .orElseThrow(() -> new RuntimeException("Error: Estado (CatalogoItem) not found for id: " + ticketRequest.getIdEstado()));

        Servicio servicio = servicioRepository.findById(ticketRequest.getIdServicio())
                .orElseThrow(() -> new RuntimeException("Error: Servicio not found for id: " + ticketRequest.getIdServicio()));

        Sucursal sucursal = sucursalRepository.findById(ticketRequest.getIdSucursal())
                .orElseThrow(() -> new RuntimeException("Error: Sucursal not found for id: " + ticketRequest.getIdSucursal()));

        Optional<SlaTicket> slaTicket = Optional.empty();
        if (ticketRequest.getIdSla() != null) {
            slaTicket = slaTicketRepository.findById(ticketRequest.getIdSla());
        }

        Optional<CatalogoItem> estadoItem = Optional.empty();
        if (ticketRequest.getIdEstadoItem() != null) {
            estadoItem = catalogoItemRepository.findById(ticketRequest.getIdEstadoItem());
        }

        Optional<CatalogoItem> prioridadItem = Optional.empty();
        if (ticketRequest.getIdPrioridadItem() != null) {
            prioridadItem = catalogoItemRepository.findById(ticketRequest.getIdPrioridadItem());
        }

        CatalogoItem categoriaItem = catalogoItemRepository.findById(ticketRequest.getIdCategoriaItem())
                .orElseThrow(() -> new RuntimeException("Error: CategoriaItem not found for id: " + ticketRequest.getIdCategoriaItem()));


        Optional<User> usuarioAsignado = Optional.empty();
        if (ticketRequest.getIdUsuarioAsignado() != null) {
            usuarioAsignado = userRepository.findById(ticketRequest.getIdUsuarioAsignado());
        }

        Empresa empresa = empresaRepository.findById(ticketRequest.getIdEmpresa())
                .orElseThrow(() -> new RuntimeException("Error: Empresa not found for id: " + ticketRequest.getIdEmpresa()));

        Cliente cliente = clienteRepository.findById(ticketRequest.getIdCliente())
                .orElseThrow(() -> new RuntimeException("Error: Cliente not found for id: " + ticketRequest.getIdCliente()));

        Empleado empleado = empleadoRepository.findById(ticketRequest.getIdEmpleado())
                .orElseThrow(() -> new RuntimeException("Error: Empleado not found for id: " + ticketRequest.getIdEmpleado()));


        Ticket ticket = new Ticket();
        // ticket.setCedulaCliente(ticketRequest.getCedulaCliente());
        // ticket.setCategoria(categoria);
        // ticket.setPrioridad(prioridad);
        // ticket.setEstado(estado);
        // ticket.setAsunto(ticketRequest.getAsunto());
        // ticket.setDescripcion(ticketRequest.getDescripcion());
        // ticket.setServicio(servicio);
        // ticket.setSucursal(sucursal);
        // ticket.setSlaTicket(slaTicket.orElse(null));
        // ticket.setEstadoItem(estadoItem.orElse(null));
        // ticket.setPrioridadItem(prioridadItem.orElse(null));
        // ticket.setCategoriaItem(categoriaItem);
        // ticket.setUsuarioCreador(usuarioCreador);
        // ticket.setUsuarioAsignado(usuarioAsignado.orElse(null));
        // ticket.setEmpresa(empresa);
        // ticket.setCliente(cliente);
        // ticket.setEmpleado(empleado);

        // ticketRepository.save(ticket);

        return ResponseEntity.ok(new MessageResponse("Ticket created successfully!"));
    }

    @GetMapping("/my-tickets")
    @PreAuthorize("hasRole('USER') or hasRole('ADMIN') or hasRole('TECHNICIAN')")
    public ResponseEntity<List<Ticket>> getMyTickets() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String currentUserName = authentication.getName();

        User reportedBy = userRepository.findByUsername(currentUserName)
                .orElseThrow(() -> new RuntimeException("Error: User not found for " + currentUserName));

        List<Ticket> tickets = ticketRepository.findByUsuarioCreador(reportedBy);
        return ResponseEntity.ok(tickets);
    }
}
