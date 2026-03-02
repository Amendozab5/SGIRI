package com.apweb.backend.model;

import jakarta.persistence.*;

@Entity
@Table(name = "network_probe_result", schema = "soporte")
public class NetworkProbeResult {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_result")
    private Integer idResult;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id_run", nullable = false)
    private NetworkProbeRun run;

    @Column(name = "zone_type", nullable = false)
    private String zoneType;

    @Column(name = "zone_id", nullable = false)
    private Integer zoneId;

    @Column(name = "latency_ms")
    private Double latencyMs;

    @Column(name = "packet_loss")
    private Double packetLoss;

    @Column(name = "http_status")
    private Integer httpStatus;

    @Column(name = "score")
    private Integer score;

    @Column(name = "level")
    private String level;

    public NetworkProbeResult() {
    }

    // Getters and Setters...
    public Integer getIdResult() {
        return idResult;
    }

    public void setIdResult(Integer idResult) {
        this.idResult = idResult;
    }

    public NetworkProbeRun getRun() {
        return run;
    }

    public void setRun(NetworkProbeRun run) {
        this.run = run;
    }

    public String getZoneType() {
        return zoneType;
    }

    public void setZoneType(String zoneType) {
        this.zoneType = zoneType;
    }

    public Integer getZoneId() {
        return zoneId;
    }

    public void setZoneId(Integer zoneId) {
        this.zoneId = zoneId;
    }

    public Double getLatencyMs() {
        return latencyMs;
    }

    public void setLatencyMs(Double latencyMs) {
        this.latencyMs = latencyMs;
    }

    public Double getPacketLoss() {
        return packetLoss;
    }

    public void setPacketLoss(Double packetLoss) {
        this.packetLoss = packetLoss;
    }

    public Integer getHttpStatus() {
        return httpStatus;
    }

    public void setHttpStatus(Integer httpStatus) {
        this.httpStatus = httpStatus;
    }

    public Integer getScore() {
        return score;
    }

    public void setScore(Integer score) {
        this.score = score;
    }

    public String getLevel() {
        return level;
    }

    public void setLevel(String level) {
        this.level = level;
    }
}
