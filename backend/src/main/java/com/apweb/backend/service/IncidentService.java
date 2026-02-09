package com.apweb.backend.service;

import com.apweb.backend.exception.ResourceNotFoundException;
import com.apweb.backend.model.EIncidentStatus;
import com.apweb.backend.model.Incident;
import com.apweb.backend.model.User;
import com.apweb.backend.repository.IncidentRepository;
import com.apweb.backend.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class IncidentService {

    @Autowired
    private IncidentRepository incidentRepository;

    @Autowired
    private UserRepository userRepository;

    @Transactional
    public Incident createIncident(String description, int creatorId) {
        User creator = userRepository.findById(creatorId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found with id: " + creatorId));
        
        Incident incident = new Incident(description, creator);
        return incidentRepository.save(incident);
    }

    @Transactional(readOnly = true)
    public List<Incident> findIncidentsByCreator(int creatorId) {
        if (!userRepository.existsById(creatorId)) {
            throw new ResourceNotFoundException("User not found with id: " + creatorId);
        }
        return incidentRepository.findByCreatorId(creatorId);
    }

    @Transactional(readOnly = true)
    public List<Incident> findAllIncidents() {
        return incidentRepository.findAll();
    }

    @Transactional
    public Incident updateIncidentStatus(int incidentId, EIncidentStatus newStatus) {
        Incident incident = incidentRepository.findById(incidentId)
                .orElseThrow(() -> new ResourceNotFoundException("Incident not found with id: " + incidentId));
        
        incident.setStatus(newStatus);
        return incidentRepository.save(incident);
    }

    @Transactional
    public Incident assignTechnician(int incidentId, int technicianId) {
        Incident incident = incidentRepository.findById(incidentId)
                .orElseThrow(() -> new ResourceNotFoundException("Incident not found with id: " + incidentId));
        
        User technician = userRepository.findById(technicianId)
                .orElseThrow(() -> new ResourceNotFoundException("Technician user not found with id: " + technicianId));

        // Optional: Check if the user has the 'TECHNICIAN' role before assigning.
        // This logic is better handled in the controller/security layer, but can be added here for extra safety.

        incident.setTechnician(technician);
        incident.setStatus(EIncidentStatus.EN_PROCESO); // Automatically update status on assignment
        return incidentRepository.save(incident);
    }
}
