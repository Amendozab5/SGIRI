package com.apweb.backend.controller;

import com.apweb.backend.service.AdminService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc; // Import AutoConfigureMockMvc
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.web.servlet.MockMvc;

import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest // Use @SpringBootTest to load the full application context
@AutoConfigureMockMvc // Auto-configure MockMvc
public class AdminControllerTests {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private AdminService adminService;

    @Test
    @WithMockUser(roles = "ADMIN")
    void deleteUser_shouldReturnOk_whenUserDeletedSuccessfully() throws Exception {
        Integer userId = 1;
        doNothing().when(adminService).deleteUser(userId);

        mockMvc.perform(delete("/api/admin/users/{id}", userId)
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value("User deleted successfully!"));

        verify(adminService, times(1)).deleteUser(userId);
    }

    @Test
    @WithMockUser(roles = "USER")
    void deleteUser_shouldReturnForbidden_whenNotAdmin() throws Exception {
        Integer userId = 1;

        mockMvc.perform(delete("/api/admin/users/{id}", userId)
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isForbidden());

        verify(adminService, never()).deleteUser(userId);
    }
}
