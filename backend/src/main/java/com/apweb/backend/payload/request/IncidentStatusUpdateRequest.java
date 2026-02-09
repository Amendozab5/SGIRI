package com.apweb.backend.payload.request;

import com.apweb.backend.model.EIncidentStatus;
import jakarta.validation.constraints.NotNull;

public class IncidentStatusUpdateRequest {
    @NotNull
    private EIncidentStatus status;

    public EIncidentStatus getStatus() {
        return status;
    }

    public void setStatus(EIncidentStatus status) {
        this.status = status;
    }
}
