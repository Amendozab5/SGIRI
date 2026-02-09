package com.apweb.backend.payload.request;

import jakarta.validation.constraints.NotBlank;

public class IncidentRequest {
    @NotBlank
    private String description;

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }
}
