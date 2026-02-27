package com.apweb.backend.controller;

import com.apweb.backend.model.*;
import com.apweb.backend.payload.request.CommentRequest;
import com.apweb.backend.payload.request.TicketRequest;
import com.apweb.backend.payload.response.MessageResponse;
import com.apweb.backend.repository.*;
import com.apweb.backend.service.TicketService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@CrossOrigin(origins = "*", maxAge = 3600)
@RestController
@RequestMapping("/api/tickets")
public class TicketController {

        @Autowired
        private TicketService ticketService;

        @Autowired
        private UserRepository userRepository;

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

        @GetMapping("/all")
        @PreAuthorize("hasRole('ADMIN_MASTER') or hasRole('ADMIN_TECNICOS')")
        public ResponseEntity<List<Ticket>> getAllTickets() {
                return ResponseEntity.ok(ticketService.getAllTickets());
        }

        @PostMapping("/{id}/assign")
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

        @GetMapping("/assigned")
        @PreAuthorize("hasRole('TECNICO') or hasRole('ADMIN_MASTER')")
        public ResponseEntity<List<Ticket>> getAssignedTickets() {
                Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
                String currentUserName = authentication.getName();

                User currentUser = userRepository.findByUsername(currentUserName)
                                .orElseThrow(() -> new RuntimeException(
                                                "Error: User not found for " + currentUserName));

                return ResponseEntity.ok(ticketService.getTicketsByAssignedUser(currentUser));
        }

        @GetMapping("/{id}")
        @PreAuthorize("hasRole('CLIENTE') or hasRole('TECNICO') or hasRole('ADMIN_MASTER') or hasRole('ADMIN_TECNICOS')")
        public ResponseEntity<Ticket> getTicketById(@PathVariable("id") Integer id) {
                return ResponseEntity.ok(ticketService.getTicketById(id));
        }

        @PostMapping("/{id}/comments")
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

        @PutMapping("/{id}/status")
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
}
