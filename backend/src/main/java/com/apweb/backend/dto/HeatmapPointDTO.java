package com.apweb.backend.dto;

import java.math.BigDecimal;

public class HeatmapPointDTO {
    private BigDecimal lat;
    private BigDecimal lng;
    private Double intensity;
    private String label;

    public HeatmapPointDTO() {}

    public HeatmapPointDTO(BigDecimal lat, BigDecimal lng, Double intensity, String label) {
        this.lat = lat;
        this.lng = lng;
        this.intensity = intensity;
        this.label = label;
    }

    public BigDecimal getLat() {
        return lat;
    }

    public void setLat(BigDecimal lat) {
        this.lat = lat;
    }

    public BigDecimal getLng() {
        return lng;
    }

    public void setLng(BigDecimal lng) {
        this.lng = lng;
    }

    public Double getIntensity() {
        return intensity;
    }

    public void setIntensity(Double intensity) {
        this.intensity = intensity;
    }

    public String getLabel() {
        return label;
    }

    public void setLabel(String label) {
        this.label = label;
    }
}
