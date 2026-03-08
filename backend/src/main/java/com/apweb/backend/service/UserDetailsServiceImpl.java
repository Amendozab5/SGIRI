package com.apweb.backend.service;

import com.apweb.backend.model.Role;
import com.apweb.backend.model.User;
import com.apweb.backend.repository.UserRepository;
import com.apweb.backend.repository.UsuarioBdRepository;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Collections;
import java.util.List;

@Service
public class UserDetailsServiceImpl implements UserDetailsService {
    private final UserRepository userRepository;
    private final UsuarioBdRepository usuarioBdRepository;

    public UserDetailsServiceImpl(UserRepository userRepository, UsuarioBdRepository usuarioBdRepository) {
        this.userRepository = userRepository;
        this.usuarioBdRepository = usuarioBdRepository;
    }

    @Override
    @Transactional
    public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new UsernameNotFoundException("User Not Found with username: " + username));

        // El rol ahora es único, lo obtenemos y lo envolvemos en una lista.
        // Spring Security suele esperar que los roles empiecen con "ROLE_".
        // Asumimos que el valor en la columna 'codigo' ya tiene este prefijo (ej:
        // "ROLE_USER").
        Role userRole = user.getRole();
        List<GrantedAuthority> authorities = Collections
                .singletonList(new SimpleGrantedAuthority("ROLE_" + userRole.getCodigo()));

        // Mapeamos el campo 'estado' a los estados que Spring Security entiende.
        String estadoCodigo = user.getEstado() != null ? user.getEstado().getCodigo() : "";
        boolean enabled = "ACTIVO".equalsIgnoreCase(estadoCodigo);
        boolean accountNonLocked = !"BLOQUEADO".equals(estadoCodigo);
        boolean accountNonExpired = true; // No tenemos esta lógica en la BD, asumimos true.
        boolean credentialsNonExpired = true; // No tenemos esta lógica en la BD, asumimos true.

        String dbUsername = null;
        List<com.apweb.backend.model.UsuarioBd> usuariosBd = usuarioBdRepository.findByUser_Id(user.getId());
        if (!usuariosBd.isEmpty()) {
            dbUsername = usuariosBd.get(0).getNombre();
        }

        // Usamos nuestro CustomUserDetails para incluir el rol f\u00edsico de la bd y el ID.
        return new com.apweb.backend.security.jwt.CustomUserDetails(
                user.getUsername(),
                user.getPassword(),
                enabled,
                accountNonExpired,
                credentialsNonExpired,
                accountNonLocked,
                authorities,
                dbUsername,
                user.getId());
    }
}
