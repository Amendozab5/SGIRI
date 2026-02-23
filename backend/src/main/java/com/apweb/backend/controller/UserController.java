package com.apweb.backend.controller;

import com.apweb.backend.payload.request.UserProfileUpdateRequest;
import com.apweb.backend.payload.response.UserProfileResponse;
import com.apweb.backend.service.UserService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

@CrossOrigin(origins = "*", maxAge = 3600)
@RestController
@RequestMapping("/api/profile")
public class UserController {

    private final UserService userService;

    public UserController(UserService userService) {
        this.userService = userService;
    }

    @GetMapping
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<UserProfileResponse> getUserProfile() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String username = authentication.getName();
        UserProfileResponse userProfile = userService.getUserProfile(username);
        return ResponseEntity.ok(userProfile);
    }

    @PutMapping
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<UserProfileResponse> updateUserProfile(@Valid @RequestBody UserProfileUpdateRequest request) {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String username = authentication.getName();
        UserProfileResponse updatedProfile = userService.updateUserProfile(username, request);
        return ResponseEntity.ok(updatedProfile);
    }

}
