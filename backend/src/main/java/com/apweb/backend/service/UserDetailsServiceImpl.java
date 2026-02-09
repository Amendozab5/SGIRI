package com.apweb.backend.service;

import com.apweb.backend.model.Role; // Keep if needed for other methods, otherwise remove
import com.apweb.backend.model.User;
import com.apweb.backend.repository.UserRepository; // Re-adding the missing import
import com.apweb.backend.security.services.UserDetailsImpl; // Import our custom UserDetailsImpl
import org.springframework.security.core.GrantedAuthority; // Keep if needed for other methods, otherwise remove
import org.springframework.security.core.authority.SimpleGrantedAuthority; // Keep if needed for other methods, otherwise remove
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

    public UserDetailsServiceImpl(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    @Override
    @Transactional
    public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new UsernameNotFoundException("User Not Found with username: " + username));

        return UserDetailsImpl.build(user); // Use our custom UserDetailsImpl
    }
}
