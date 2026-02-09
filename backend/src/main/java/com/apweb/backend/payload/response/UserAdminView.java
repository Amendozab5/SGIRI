package com.apweb.backend.payload.response;

import java.time.LocalDateTime;
import java.util.List;

public class UserAdminView {
    private Integer id;
    private String username;
    private String fullName; // New field
    private String email;
    private List<String> roles;
    private String estado; // New field
    private LocalDateTime lastLogin; // New field
    private LocalDateTime fechaCreacion; // New field

    public UserAdminView(Integer id, String username, String fullName, String email, List<String> roles, String estado, LocalDateTime lastLogin, LocalDateTime fechaCreacion) {
        this.id = id;
        this.username = username;
        this.fullName = fullName;
        this.email = email;
        this.roles = roles;
        this.estado = estado;
        this.lastLogin = lastLogin;
        this.fechaCreacion = fechaCreacion;
    }

    // Getters and Setters
    public Integer getId() {
        return id;
    }

    public void setId(Integer id) {
        this.id = id;
    }

    public String getUsername() {
        return username;
    }

    public void setUsername(String username) {
        this.username = username;
    }

    public String getFullName() {
        return fullName;
    }

    public void setFullName(String fullName) {
        this.fullName = fullName;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public List<String> getRoles() {
        return roles;
    }

    public void setRoles(List<String> roles) {
        this.roles = roles;
    }

    public String getEstado() {
        return estado;
    }

    public void setEstado(String estado) {
        this.estado = estado;
    }

    public LocalDateTime getLastLogin() {
        return lastLogin;
    }

    public void setLastLogin(LocalDateTime lastLogin) {
        this.lastLogin = lastLogin;
    }

    public LocalDateTime getFechaCreacion() {
        return fechaCreacion;
    }

    public void setFechaCreacion(LocalDateTime fechaCreacion) {
        this.fechaCreacion = fechaCreacion;
    }
}
