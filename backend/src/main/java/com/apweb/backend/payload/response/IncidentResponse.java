package com.apweb.backend.payload.response;

import com.apweb.backend.model.EIncidentStatus;
import com.apweb.backend.model.Incident;

import java.time.LocalDateTime;

public class IncidentResponse {
    private int id;
    private String description;
    private EIncidentStatus status;
    private String creatorUsername;
    private String technicianUsername;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    public IncidentResponse(int id, String description, EIncidentStatus status, String creatorUsername, String technicianUsername, LocalDateTime createdAt, LocalDateTime updatedAt) {
        this.id = id;
        this.description = description;
        this.status = status;
        this.creatorUsername = creatorUsername;
        this.technicianUsername = technicianUsername;
        this.createdAt = createdAt;
        this.updatedAt = updatedAt;
    }

    public static IncidentResponse fromIncident(Incident incident) {
        String techUsername = incident.getTechnician() != null ? incident.getTechnician().getUsername() : null;
        return new IncidentResponse(
            incident.getId(),
            incident.getDescription(),
            incident.getStatus(),
            incident.getCreator().getUsername(),
            techUsername,
            incident.getCreatedAt(),
            incident.getUpdatedAt()
        );
    }
    
    // Getters and Setters
    public int getId() { return id; }
    public void setId(int id) { this.id = id; }
    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }
    public EIncidentStatus getStatus() { return status; }
    public void setStatus(EIncidentStatus status) { this.status = status; }
    public String getCreatorUsername() { return creatorUsername; }
    public void setCreatorUsername(String creatorUsername) { this.creatorUsername = creatorUsername; }
    public String getTechnicianUsername() { return technicianUsername; }
    public void setTechnicianUsername(String technicianUsername) { this.technicianUsername = technicianUsername; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(LocalDateTime updatedAt) { this.updatedAt = updatedAt; }
}
