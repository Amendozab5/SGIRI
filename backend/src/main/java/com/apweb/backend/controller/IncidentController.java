package com.apweb.backend.controller;

import com.apweb.backend.model.Incident;
import com.apweb.backend.payload.request.IncidentRequest;
import com.apweb.backend.payload.request.IncidentStatusUpdateRequest;
import com.apweb.backend.payload.response.IncidentResponse;
import com.apweb.backend.payload.response.MessageResponse;
import com.apweb.backend.security.services.UserDetailsImpl;
import com.apweb.backend.service.IncidentService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.stream.Collectors;

@CrossOrigin(origins = "*", maxAge = 3600)
@RestController
@RequestMapping("/api/incidents")
public class IncidentController {

    @Autowired
    private IncidentService incidentService;

    @PostMapping
    @PreAuthorize("hasRole('USER') or hasRole('TECHNICIAN') or hasRole('ADMIN')")
    public ResponseEntity<?> createIncident(@Valid @RequestBody IncidentRequest incidentRequest) {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        UserDetailsImpl userDetails = (UserDetailsImpl) authentication.getPrincipal();
        
        Incident incident = incidentService.createIncident(incidentRequest.getDescription(), userDetails.getId());

        return ResponseEntity.ok(IncidentResponse.fromIncident(incident));
    }

    @GetMapping("/my-incidents")
    @PreAuthorize("hasRole('USER') or hasRole('TECHNICIAN') or hasRole('ADMIN')")
    public ResponseEntity<List<IncidentResponse>> getCurrentUserIncidents() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        UserDetailsImpl userDetails = (UserDetailsImpl) authentication.getPrincipal();

        List<IncidentResponse> incidents = incidentService.findIncidentsByCreator(userDetails.getId())
                .stream()
                .map(IncidentResponse::fromIncident)
                .collect(Collectors.toList());
        
        return ResponseEntity.ok(incidents);
    }

    @GetMapping
    @PreAuthorize("hasRole('TECHNICIAN') or hasRole('ADMIN')")
    public ResponseEntity<List<IncidentResponse>> getAllIncidents() {
        List<IncidentResponse> incidents = incidentService.findAllIncidents()
                .stream()
                .map(IncidentResponse::fromIncident)
                .collect(Collectors.toList());
        
        return ResponseEntity.ok(incidents);
    }
    
    @PutMapping("/{id}/status")
    @PreAuthorize("hasRole('TECHNICIAN') or hasRole('ADMIN')")
    public ResponseEntity<?> updateIncidentStatus(@PathVariable("id") int incidentId, @Valid @RequestBody IncidentStatusUpdateRequest statusRequest) {
        Incident updatedIncident = incidentService.updateIncidentStatus(incidentId, statusRequest.getStatus());
        return ResponseEntity.ok(IncidentResponse.fromIncident(updatedIncident));
    }

    @PutMapping("/{id}/assign")
    @PreAuthorize("hasRole('TECHNICIAN') or hasRole('ADMIN')")
    public ResponseEntity<?> assignTechnicianToIncident(@PathVariable("id") int incidentId) {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        UserDetailsImpl userDetails = (UserDetailsImpl) authentication.getPrincipal();

        Incident assignedIncident = incidentService.assignTechnician(incidentId, userDetails.getId());
        return ResponseEntity.ok(IncidentResponse.fromIncident(assignedIncident));
    }
}
