package com.apweb.backend.security.jwt;

import org.springframework.security.core.GrantedAuthority;
import java.util.Collection;

public class CustomUserDetails extends org.springframework.security.core.userdetails.User {

    private final String dbUsername;
    private final Integer idUsuario;

    public CustomUserDetails(String username, String password, boolean enabled, boolean accountNonExpired,
            boolean credentialsNonExpired, boolean accountNonLocked,
            Collection<? extends GrantedAuthority> authorities, String dbUsername, Integer idUsuario) {
        super(username, password, enabled, accountNonExpired, credentialsNonExpired, accountNonLocked, authorities);
        this.dbUsername = dbUsername;
        this.idUsuario = idUsuario;
    }

    public String getDbUsername() {
        return dbUsername;
    }

    public Integer getIdUsuario() {
        return idUsuario;
    }
}
