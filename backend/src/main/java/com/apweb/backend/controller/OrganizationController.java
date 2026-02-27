package com.apweb.backend.controller;

import com.apweb.backend.model.Area;
import com.apweb.backend.model.Cargo;
import com.apweb.backend.service.OrganizationService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@CrossOrigin(origins = "http://localhost:4200", maxAge = 3600, allowCredentials = "true")
@RestController
@RequestMapping("/api/organization")
public class OrganizationController {

    @Autowired
    private OrganizationService organizationService;

    @GetMapping("/areas")
    public List<Area> getAllAreas() {
        return organizationService.getAllAreas();
    }

    @GetMapping("/cargos")
    public List<Cargo> getAllCargos() {
        return organizationService.getAllCargos();
    }
}
