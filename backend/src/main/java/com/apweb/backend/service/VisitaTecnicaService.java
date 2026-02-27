package com.apweb.backend.service;

import com.apweb.backend.model.*;
import com.apweb.backend.payload.request.VisitaRequest;
import com.apweb.backend.repository.*;
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
        private NotificationService notificationService;

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

                // Notificar al técnico
                notificationService.createNotification(creator, tecnico, ticket,
                                "Nueva Visita Programada: Ticket #" + ticket.getIdTicket(),
                                "Se le ha programado una visita para el " + visita.getFechaVisita() + " a las "
                                                + visita.getHoraInicio());

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

                        notificationService.createNotification(updater, nuevoTecnico, visita.getTicket(),
                                        "Visita Técnica Reasignada: Ticket #" + visita.getTicket().getIdTicket(),
                                        "Se le ha reasignado una visita para el " + visita.getFechaVisita());
                }

                return visitaTecnicaRepository.save(visita);
        }
}
