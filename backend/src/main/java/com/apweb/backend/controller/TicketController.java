package com.apweb.backend.controller;

import com.apweb.backend.dto.TechnicianDTO;
import com.apweb.backend.dto.DocumentoEmpleadoDTO;
import com.apweb.backend.dto.AssignMultipleRequest;
import com.apweb.backend.dto.ReassignRequest;

import com.apweb.backend.model.*;
import com.apweb.backend.payload.request.CommentRequest;
import com.apweb.backend.payload.request.InformeTrabajoTecnicoRequest;
import com.apweb.backend.payload.request.RatingRequest;
import com.apweb.backend.payload.request.TicketRequest;
import com.apweb.backend.payload.response.MessageResponse;
import com.apweb.backend.repository.*;
import com.apweb.backend.service.TicketService;
import com.apweb.backend.service.CloudinaryService;
import jakarta.validation.Valid;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;
import org.springframework.core.io.InputStreamResource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import java.io.ByteArrayInputStream;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/tickets")
public class TicketController {

        @Autowired
        private TicketService ticketService;

        @Autowired
        private UserRepository userRepository;

        @Autowired
        private CloudinaryService cloudinaryService;

        @PostMapping
        @PreAuthorize("hasRole('CLIENTE') or hasRole('ADMIN_MASTER')")
        public ResponseEntity<?> createTicket(@Valid @RequestBody TicketRequest ticketRequest) {
                Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
                String currentUserName = authentication.getName();

                User currentUser = userRepository.findByUsername(currentUserName)
                                .orElseThrow(() -> new RuntimeException(
                                                "Error: User not found for " + currentUserName));

                Ticket ticket = ticketService.createTicketForClient(currentUser, ticketRequest);

                return ResponseEntity
                                .ok(new MessageResponse("Ticket creado exitosamente con ID: " + ticket.getIdTicket()));
        }

        @PostMapping("/upload-evidence")
        @PreAuthorize("hasRole('CLIENTE') or hasRole('ADMIN_MASTER')")
        public ResponseEntity<?> uploadEvidence(@RequestParam("file") MultipartFile file) {
            String url = cloudinaryService.upload(file, "evidencias_tickets");
            return ResponseEntity.ok(java.util.Map.of("url", url));
        }

        @GetMapping("/all")
        @PreAuthorize("hasRole('ADMIN_MASTER') or hasRole('ADMIN_TECNICOS')")
        public ResponseEntity<List<Ticket>> getAllTickets() {
                return ResponseEntity.ok(ticketService.getAllTickets());
        }

        @PostMapping("/{id:[0-9]+}/assign")
        @PreAuthorize("hasRole('ADMIN_MASTER') or hasRole('ADMIN_TECNICOS')")
        public ResponseEntity<?> assignTicket(@PathVariable("id") Integer id,
                        @RequestBody Map<String, Integer> payload) {
                Integer userId = payload.get("userId");
                if (userId == null) {
                        return ResponseEntity.badRequest().body(new MessageResponse("Error: userId is required"));
                }

                Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
                String currentUserName = authentication.getName();
                User currentUser = userRepository.findByUsername(currentUserName)
                                .orElseThrow(() -> new RuntimeException("Error: User not found"));

                ticketService.assignTicket(id, userId, currentUser);
                return ResponseEntity.ok(new MessageResponse("Ticket asignado exitosamente"));
        }

        @PostMapping("/{id:[0-9]+}/assign-multiple")
        @PreAuthorize("hasRole('ADMIN_MASTER') or hasRole('ADMIN_TECNICOS')")
        public ResponseEntity<?> assignTicketMultiple(@PathVariable("id") Integer id,
                        @RequestBody AssignMultipleRequest payload) {
                List<Integer> userIds = payload.getUserIds();
                String groupCode = payload.getGroupCode();

                if (userIds == null || userIds.isEmpty()) {
                        return ResponseEntity.badRequest().body(new MessageResponse("Error: userIds is required"));
                }

                Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
                String currentUserName = authentication.getName();
                User currentUser = userRepository.findByUsername(currentUserName)
                                .orElseThrow(() -> new RuntimeException("Error: User not found"));

                ticketService.assignTicketMultiple(id, userIds, currentUser, groupCode);
                return ResponseEntity.ok(new MessageResponse("Ticket asignado al grupo exitosamente"));
        }

        @PostMapping("/{id:[0-9]+}/reassign")
        @PreAuthorize("hasRole('ADMIN_MASTER')")
        public ResponseEntity<?> reassignTicket(@PathVariable("id") Integer id,
                        @RequestBody ReassignRequest payload) {
                Integer userId = payload.getUserId();
                String notaReasignacion = payload.getNotaReasignacion();

                if (userId == null) {
                        return ResponseEntity.badRequest().body(new MessageResponse("Error: userId is required"));
                }
                if (notaReasignacion == null || notaReasignacion.trim().isEmpty()) {
                        return ResponseEntity.badRequest().body(new MessageResponse("Error: notaReasignacion is required"));
                }

                Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
                String currentUserName = authentication.getName();
                User currentUser = userRepository.findByUsername(currentUserName)
                                .orElseThrow(() -> new RuntimeException("Error: User not found"));

                ticketService.reassignTicket(id, userId, currentUser, notaReasignacion);
                return ResponseEntity.ok(new MessageResponse("Ticket reasignado exitosamente"));
        }

        @GetMapping("/tecnicos")
        @PreAuthorize("hasRole('ADMIN_MASTER') or hasRole('ADMIN_TECNICOS')")
        public ResponseEntity<List<TechnicianDTO>> getAllTechniciansDetailed() {
                return ResponseEntity.ok(ticketService.getAllTechniciansDetailed());
        }

        @GetMapping("/tecnicos/{userId}/documentos")
        @PreAuthorize("hasRole('ADMIN_MASTER') or hasRole('ADMIN_TECNICOS')")
        public ResponseEntity<List<DocumentoEmpleadoDTO>> getTechnicianDocuments(@PathVariable("userId") Integer userId) {
                return ResponseEntity.ok(ticketService.getTechnicianDocuments(userId));
        }

        @GetMapping("/my-tickets")
        @PreAuthorize("hasRole('CLIENTE') or hasRole('ADMIN_MASTER')")
        public ResponseEntity<List<Ticket>> getMyTickets() {
                Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
                String currentUserName = authentication.getName();

                User currentUser = userRepository.findByUsername(currentUserName)
                                .orElseThrow(() -> new RuntimeException(
                                                "Error: User not found for " + currentUserName));

                List<Ticket> tickets = ticketService.getTicketsByUser(currentUser);
                return ResponseEntity.ok(tickets);
        }

        @GetMapping("/my-tickets-paged")
        @PreAuthorize("hasRole('CLIENTE') or hasRole('ADMIN_MASTER')")
        public ResponseEntity<org.springframework.data.domain.Page<Ticket>> getMyTicketsPaged(
                        @RequestParam(name = "page", defaultValue = "0") int page,
                        @RequestParam(name = "size", defaultValue = "10") int size,
                        @RequestParam(name = "searchTerm", required = false) String searchTerm,
                        @RequestParam(name = "statusId", required = false) Integer statusId,
                        @RequestParam(name = "categoryId", required = false) Integer categoryId) {
                Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
                String currentUserName = authentication.getName();

                User currentUser = userRepository.findByUsername(currentUserName)
                                .orElseThrow(() -> new RuntimeException("Error: User not found"));

                org.springframework.data.domain.Pageable pageable = org.springframework.data.domain.PageRequest.of(page,
                                size,
                                org.springframework.data.domain.Sort.by("fechaCreacion").descending());

                return ResponseEntity.ok(ticketService.getTicketsByUserPaginated(
                                currentUser, searchTerm, statusId, categoryId, pageable));
        }

        @GetMapping("/assigned")
        @PreAuthorize("hasRole('TECNICO') or hasRole('ADMIN_MASTER')")
        public ResponseEntity<?> getAssignedTickets() {
                try {
                        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
                        String currentUserName = authentication.getName();

                        User currentUser = userRepository.findByUsername(currentUserName)
                                        .orElseThrow(() -> new RuntimeException(
                                                        "Error: User not found for " + currentUserName));

                        return ResponseEntity.ok(ticketService.getTicketsByAssignedUser(currentUser));
                } catch (Exception e) {
                        e.printStackTrace();
                        String errorMsg = e.getClass().getName() + ": " + e.getMessage();
                        if (e.getCause() != null) {
                            errorMsg += " | Caused by: " + e.getCause().getClass().getName() + ": " + e.getCause().getMessage();
                        }
                        return ResponseEntity.status(500).body(new MessageResponse("Error Backend: " + errorMsg));
                }
        }

        @PostMapping("/{id:[0-9]+}/comments")
        @PreAuthorize("hasRole('CLIENTE') or hasRole('TECNICO') or hasRole('ADMIN_MASTER') or hasRole('ADMIN_TECNICOS')")
        public ResponseEntity<?> addComment(@PathVariable("id") Integer id,
                        @Valid @RequestBody CommentRequest commentRequest) {
                Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
                String currentUserName = authentication.getName();

                User currentUser = userRepository.findByUsername(currentUserName)
                                .orElseThrow(() -> new RuntimeException("Error: User not found"));

                ticketService.addComment(id, currentUser, commentRequest.getComentario(),
                                commentRequest.getEsInterno());
                return ResponseEntity.ok(new MessageResponse("Comentario agregado exitosamente"));
        }

        @GetMapping("/{id:[0-9]+}")
        @PreAuthorize("hasRole('CLIENTE') or hasRole('TECNICO') or hasRole('ADMIN_MASTER') or hasRole('ADMIN_TECNICOS')")
        public ResponseEntity<Ticket> getTicketById(@PathVariable("id") Integer id) {
                return ResponseEntity.ok(ticketService.getTicketById(id));
        }

        @PutMapping("/{id:[0-9]+}/status")
        @PreAuthorize("hasRole('TECNICO') or hasRole('ADMIN_MASTER') or hasRole('ADMIN_TECNICOS')")
        public ResponseEntity<?> updateStatus(@PathVariable("id") Integer id,
                        @RequestBody Map<String, String> payload) {
                String statusCode = payload.get("statusCode");
                String observation = payload.get("observation");

                if (statusCode == null) {
                        return ResponseEntity.badRequest().body(new MessageResponse("Error: statusCode is required"));
                }

                Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
                String currentUserName = authentication.getName();

                User currentUser = userRepository.findByUsername(currentUserName)
                                .orElseThrow(() -> new RuntimeException("Error: User not found"));

                ticketService.updateTicketStatus(id, currentUser, statusCode, observation);
                return ResponseEntity.ok(new MessageResponse("Estado del ticket actualizado exitosamente"));
        }

        @PostMapping("/{id:[0-9]+}/rating")
        @PreAuthorize("hasRole('CLIENTE') or hasRole('ADMIN_MASTER')")
        public ResponseEntity<?> rateTicket(@PathVariable("id") Integer id,
                        @Valid @RequestBody RatingRequest ratingRequest) {
                Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
                String currentUserName = authentication.getName();
                User currentUser = userRepository.findByUsername(currentUserName)
                                .orElseThrow(() -> new RuntimeException("Error: User not found"));

                if (ratingRequest.getPuntuacion() == null) {
                        return ResponseEntity.badRequest().body(new MessageResponse("Error: puntuacion is required"));
                }
                ticketService.rateTicket(id, currentUser, ratingRequest.getPuntuacion(),
                                ratingRequest.getComentario());
                return ResponseEntity.ok(new MessageResponse("Calificación registrada exitosamente"));
        }

        @GetMapping("/tecnico/{idTecnico}/stats")
        @PreAuthorize("hasRole('ADMIN_MASTER') or hasRole('ADMIN_TECNICOS') or hasRole('TECNICO')")
        public ResponseEntity<?> getTechnicianRatingStats(@PathVariable("idTecnico") Integer idTecnico) {
                User tecnico = userRepository.findById(idTecnico)
                                .orElseThrow(() -> new RuntimeException(
                                                "Error: Technician not found with ID: " + idTecnico));

                Double promedio = ticketService.getAvgRatingByTecnico(tecnico);
                Long totalCalificados = ticketService.countRatedTicketsByTecnico(tecnico);
                Long totalTickets = ticketService.countTicketsByTecnico(tecnico);

                return ResponseEntity.ok(java.util.Map.of(
                                "promedio", promedio != null ? promedio : 0.0,
                                "totalCalificados", totalCalificados,
                                "totalTickets", totalTickets));
        }

        // ─── Informe Técnico ───────────────────────────────────────────────────

        /**
         * Submit a technical work report for a ticket.
         * The ticket must be in EN_PROCESO state.
         * On success, the ticket transitions to RESUELTO or ABIERTO (if not resolved).
         */
        @PostMapping("/{id:[0-9]+}/informe")
        @PreAuthorize("hasRole('TECNICO') or hasRole('ADMIN_MASTER')")
        public ResponseEntity<?> submitInforme(
                        @PathVariable("id") Integer id,
                        @RequestBody InformeTrabajoTecnicoRequest informeRequest) {

                Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
                String currentUserName = authentication.getName();
                User currentUser = userRepository.findByUsername(currentUserName)
                                .orElseThrow(() -> new RuntimeException("Error: User not found"));

                try {
                        InformeTrabajoTecnico informe = ticketService.submitInformeTecnico(id, currentUser,
                                        informeRequest);
                        return ResponseEntity.ok(informe);
                } catch (Exception e) {
                        e.printStackTrace();
                        throw e;
                }
        }

        /**
         * Get the technical work report for a ticket (if it exists).
         */
        @GetMapping("/{id:[0-9]+}/informe")
        @PreAuthorize("hasRole('TECNICO') or hasRole('ADMIN_MASTER') or hasRole('ADMIN_TECNICOS')")
        public ResponseEntity<?> getInforme(@PathVariable("id") Integer id) {
                List<InformeTrabajoTecnico> informes = ticketService.getInformeTecnico(id);
                if (informes == null || informes.isEmpty()) {
                        return ResponseEntity.noContent().build();
                }
                return ResponseEntity.ok(informes);
        }

        @GetMapping("/{id:[0-9]+}/inventario-usado")
        @PreAuthorize("hasRole('TECNICO') or hasRole('ADMIN_MASTER') or hasRole('ADMIN_TECNICOS')")
        public ResponseEntity<?> getInventarioUsado(@PathVariable("id") Integer id) {
                return ResponseEntity.ok(ticketService.getInventarioUsado(id));
        }

        @GetMapping("/informe/frecuencias")
        @PreAuthorize("hasRole('TECNICO') or hasRole('ADMIN_MASTER')")
        public ResponseEntity<?> getFrecuencias() {
                return ResponseEntity.ok(ticketService.getOptionFrequencies());
        }

        @GetMapping("/{id:[0-9]+}/pdf")
        @PreAuthorize("hasRole('TECNICO') or hasRole('ADMIN_MASTER') or hasRole('ADMIN_TECNICOS') or hasRole('CLIENTE')")
        public ResponseEntity<InputStreamResource> exportTicketPdf(@PathVariable("id") Integer id) {
                ByteArrayInputStream bis = ticketService.generateTicketPdf(id);

                HttpHeaders headers = new HttpHeaders();
                headers.add("Content-Disposition", "attachment; filename=ticket_" + id + ".pdf");

                return ResponseEntity
                                .ok()
                                .headers(headers)
                                .contentType(MediaType.APPLICATION_PDF)
                                .body(new InputStreamResource(bis));
        }

        @GetMapping("/pending-visit")
        @PreAuthorize("hasRole('ADMIN_MASTER') or hasRole('ADMIN_TECNICOS')")
        public ResponseEntity<List<Ticket>> getTicketsPendingVisit() {
                return ResponseEntity.ok(ticketService.getTicketsPendingVisit());
        }

        /**
         * Genera la Hoja de Servicio Digital firmada por el cliente.
         * Recibe la firma como imagen PNG multipart, genera el PDF y lo devuelve como descarga.
         * Además sube el PDF a Cloudinary y lo registra en soporte.documento_ticket.
         */
        @PostMapping("/{id:[0-9]+}/hoja-servicio")
        @PreAuthorize("hasRole('TECNICO') or hasRole('ADMIN_MASTER') or hasRole('ADMIN_TECNICOS')")
        public ResponseEntity<InputStreamResource> generarHojaServicio(
                        @PathVariable("id") Integer id,
                        @RequestParam(value = "firmaCliente", required = false) org.springframework.web.multipart.MultipartFile firmaClienteFile,
                        @RequestParam(value = "firmaTecnico", required = false) org.springframework.web.multipart.MultipartFile firmaTecnicoFile) {

                Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
                String currentUserName = authentication.getName();
                User currentUser = userRepository.findByUsername(currentUserName)
                                .orElseThrow(() -> new RuntimeException("Error: User not found"));

                byte[] signatureClienteBytes = null;
                if (firmaClienteFile != null && !firmaClienteFile.isEmpty()) {
                        try {
                                signatureClienteBytes = firmaClienteFile.getBytes();
                        } catch (Exception e) {}
                }

                byte[] signatureTecnicoBytes = null;
                if (firmaTecnicoFile != null && !firmaTecnicoFile.isEmpty()) {
                        try {
                                signatureTecnicoBytes = firmaTecnicoFile.getBytes();
                        } catch (Exception e) {}
                }

                ByteArrayInputStream bis = ticketService.generateHojaServicioPdf(id, signatureClienteBytes, signatureTecnicoBytes, currentUser);

                HttpHeaders headers = new HttpHeaders();
                headers.add("Content-Disposition", "attachment; filename=hoja_servicio_" + id + ".pdf");

                return ResponseEntity
                                .ok()
                                .headers(headers)
                                .contentType(MediaType.APPLICATION_PDF)
                                .body(new InputStreamResource(bis));
        }
}
