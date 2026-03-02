package com.apweb.backend.dto;

import java.time.LocalDateTime;

public class NetworkMapDTO {
    private Integer zoneId;
    private String zoneName;
    private Integer openTickets;
    private String maxPriority;
    private Integer scoreTickets;
    private Integer scoreFinal;
    private String level;
    private String dataSource;
    private Double latencyOverallMs;
    private LocalDateTime generatedAt;
    private LocalDateTime lastSuccessfulCheckAt;

    public NetworkMapDTO() {
    }

    // Getters and Setters
    public Integer getZoneId() {
        return zoneId;
    }

    public void setZoneId(Integer zoneId) {
        this.zoneId = zoneId;
    }

    public String getZoneName() {
        return zoneName;
    }

    public void setZoneName(String zoneName) {
        this.zoneName = zoneName;
    }

    public Integer getOpenTickets() {
        return openTickets;
    }

    public void setOpenTickets(Integer openTickets) {
        this.openTickets = openTickets;
    }

    public String getMaxPriority() {
        return maxPriority;
    }

    public void setMaxPriority(String maxPriority) {
        this.maxPriority = maxPriority;
    }

    public Integer getScoreTickets() {
        return scoreTickets;
    }

    public void setScoreTickets(Integer scoreTickets) {
        this.scoreTickets = scoreTickets;
    }

    public Integer getScoreFinal() {
        return scoreFinal;
    }

    public void setScoreFinal(Integer scoreFinal) {
        this.scoreFinal = scoreFinal;
    }

    public String getLevel() {
        return level;
    }

    public void setLevel(String level) {
        this.level = level;
    }

    public String getDataSource() {
        return dataSource;
    }

    public void setDataSource(String dataSource) {
        this.dataSource = dataSource;
    }

    public Double getLatencyOverallMs() {
        return latencyOverallMs;
    }

    public void setLatencyOverallMs(Double latencyOverallMs) {
        this.latencyOverallMs = latencyOverallMs;
    }

    public LocalDateTime getGeneratedAt() {
        return generatedAt;
    }

    public void setGeneratedAt(LocalDateTime generatedAt) {
        this.generatedAt = generatedAt;
    }

    public LocalDateTime getLastSuccessfulCheckAt() {
        return lastSuccessfulCheckAt;
    }

    public void setLastSuccessfulCheckAt(LocalDateTime lastSuccessfulCheckAt) {
        this.lastSuccessfulCheckAt = lastSuccessfulCheckAt;
    }
}
