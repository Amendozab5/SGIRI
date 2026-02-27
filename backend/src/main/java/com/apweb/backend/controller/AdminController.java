package com.apweb.backend.controller;

import com.apweb.backend.payload.request.UserCreateRequest;
import com.apweb.backend.payload.request.UserUpdateRequest;
import com.apweb.backend.payload.response.UserAdminView;
import com.apweb.backend.service.AdminService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@CrossOrigin(origins = "http://localhost:4200", maxAge = 3600, allowCredentials = "true")
@RestController
@RequestMapping("/api/admin")
@PreAuthorize("hasRole('ADMIN_MASTER')")
public class AdminController {

    @Autowired
    private AdminService adminService;

    @GetMapping("/roles")
    public List<String> getRoles() {
        return adminService.getRoles();
    }

    @GetMapping("/users")
    public List<UserAdminView> getAllUsers(@RequestParam(name = "role", required = false) String role) {
        return adminService.getAllUsersForAdmin(role);
    }

    @PostMapping("/users")
    public ResponseEntity<UserAdminView> createUser(@Valid @RequestBody UserCreateRequest request) {
        UserAdminView newUser = adminService.createUser(request);
        return new ResponseEntity<>(newUser, HttpStatus.CREATED);
    }

    @PutMapping("/users/{id}")
    public ResponseEntity<UserAdminView> updateUser(@PathVariable(name = "id") Integer id,
            @Valid @RequestBody UserUpdateRequest request) {
        UserAdminView updatedUser = adminService.updateUser(id, request);
        return ResponseEntity.ok(updatedUser);
    }

    @PutMapping("/users/{id}/status")
    public ResponseEntity<?> toggleUserStatus(@PathVariable(name = "id") Integer id,
            @RequestBody Map<String, String> payload) {
        String estado = payload.get("estado");
        if (estado == null || (!estado.equals("ACTIVO") && !estado.equals("INACTIVO"))) {
            return new ResponseEntity<>(Map.of("message", "Invalid status provided. Must be 'ACTIVO' or 'INACTIVO'."),
                    HttpStatus.BAD_REQUEST);
        }
        adminService.toggleUserStatus(id, estado);
        return ResponseEntity.ok(Map.of("message", "User status updated successfully!"));
    }

    @DeleteMapping("/users/{id}")
    public ResponseEntity<?> deleteUser(@PathVariable(name = "id") Integer id) {
        adminService.deleteUser(id);
        return ResponseEntity.ok(Map.of("message", "User deleted successfully!"));
    }
}
