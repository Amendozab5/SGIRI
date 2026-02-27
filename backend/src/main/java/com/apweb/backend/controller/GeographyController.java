package com.apweb.backend.controller;

import com.apweb.backend.model.Canton;
import com.apweb.backend.model.Ciudad;
import com.apweb.backend.model.Pais;
import com.apweb.backend.service.GeographyService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@CrossOrigin(origins = "*", maxAge = 3600)
@RestController
@RequestMapping("/api/geography")
public class GeographyController {

    private final GeographyService geographyService;

    public GeographyController(GeographyService geographyService) {
        this.geographyService = geographyService;
    }

    @GetMapping("/paises")
    public ResponseEntity<List<Pais>> getAllPaises() {
        List<Pais> paises = geographyService.getAllPaises();
        return ResponseEntity.ok(paises);
    }

    @GetMapping("/ciudades")
    public ResponseEntity<List<Ciudad>> getCiudadesByPais(@RequestParam(name = "paisId") Integer paisId) {
        List<Ciudad> ciudades = geographyService.getCiudadesByPaisId(paisId);
        return ResponseEntity.ok(ciudades);
    }

    @GetMapping("/cantones")
    public ResponseEntity<List<Canton>> getCantonesByCiudad(@RequestParam(name = "ciudadId") Integer ciudadId) {
        List<Canton> cantones = geographyService.getCantonesByCiudadId(ciudadId);
        return ResponseEntity.ok(cantones);
    }
}
