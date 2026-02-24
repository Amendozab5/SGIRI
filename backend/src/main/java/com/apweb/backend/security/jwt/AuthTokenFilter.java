package com.apweb.backend.security.jwt;

import com.apweb.backend.service.UserDetailsServiceImpl;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;

@Component
public class AuthTokenFilter extends OncePerRequestFilter {
    private final JwtUtils jwtUtils;
    private final UserDetailsServiceImpl userDetailsService;

    private static final Logger logger = LoggerFactory.getLogger(AuthTokenFilter.class);

    @Autowired
    public AuthTokenFilter(JwtUtils jwtUtils, UserDetailsServiceImpl userDetailsService) {
        this.jwtUtils = jwtUtils;
        this.userDetailsService = userDetailsService;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
            throws ServletException, IOException {
        try {
            String headerAuth = request.getHeader("Authorization");
            logger.debug("Authorization Header: {}", headerAuth);

            String jwt = parseJwt(request);
            logger.debug("JWT Token: {}", jwt);

            if (jwt != null) {
                boolean isTokenValid = jwtUtils.validateJwtToken(jwt);
                logger.debug("Is JWT Token Valid: {}", isTokenValid);

                if (isTokenValid) {
                    String username = jwtUtils.getUserNameFromJwtToken(jwt);
                    logger.debug("Username from JWT: {}", username);

                    UserDetails userDetails = userDetailsService.loadUserByUsername(username);

                    if (userDetails.isEnabled()) {
                        UsernamePasswordAuthenticationToken authentication = new UsernamePasswordAuthenticationToken(
                                userDetails,
                                null,
                                userDetails.getAuthorities());

                        authentication.setDetails(new WebAuthenticationDetailsSource().buildDetails(request));

                        SecurityContextHolder.getContext().setAuthentication(authentication);
                        logger.debug("User authenticated successfully.");
                    } else {
                        logger.warn("User {} is disabled. Authentication rejected.", username);
                    }
                } else {
                    logger.warn("JWT Token is invalid or expired after validation.");
                }
            } else {
                logger.warn("No JWT token found in request.");
            }
        } catch (Exception e) {
            logger.error("Cannot set user authentication: {}", e.getMessage(), e);
        }

        filterChain.doFilter(request, response);
    }

    private String parseJwt(HttpServletRequest request) {
        String headerAuth = request.getHeader("Authorization");

        if (StringUtils.hasText(headerAuth) && headerAuth.startsWith("Bearer ")) {
            return headerAuth.substring(7);
        }

        return null;
    }
}