package com.apweb.backend.controller;

import com.apweb.backend.model.Servicio;
import com.apweb.backend.repository.ServicioRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@CrossOrigin(origins = "*", maxAge = 3600)
@RestController
@RequestMapping("/api/servicios")
public class ServicioController {

    @Autowired
    private ServicioRepository servicioRepository;

    @GetMapping
    public ResponseEntity<List<Servicio>> getAllServicios() {
        return ResponseEntity.ok(servicioRepository.findAll());
    }

    @GetMapping("/empresa/{id}")
    public ResponseEntity<List<Servicio>> getServiciosByEmpresa(@PathVariable("id") Integer id) {
        return ResponseEntity.ok(servicioRepository.findByEmpresas_Id(id));
    }
}
