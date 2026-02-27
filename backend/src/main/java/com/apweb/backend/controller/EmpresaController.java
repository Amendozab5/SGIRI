package com.apweb.backend.controller;

import com.apweb.backend.model.Empresa;
import com.apweb.backend.model.Sucursal;
import com.apweb.backend.payload.request.EmpresaRequest;
import com.apweb.backend.payload.request.SucursalRequest;
import com.apweb.backend.service.EmpresaService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@CrossOrigin(origins = "http://localhost:4200", maxAge = 3600, allowCredentials = "true")
@RestController
@RequestMapping("/api/empresas")
public class EmpresaController {

    @Autowired
    private EmpresaService empresaService;

    @GetMapping
    public ResponseEntity<List<Empresa>> getAllEmpresas() {
        return ResponseEntity.ok(empresaService.getAllEmpresas());
    }

    @PostMapping
    public ResponseEntity<Empresa> createEmpresa(@Valid @RequestBody EmpresaRequest request) {
        return ResponseEntity.ok(empresaService.createEmpresa(request));
    }

    @GetMapping("/isps")
    public ResponseEntity<List<Empresa>> getAllISPs() {
        return ResponseEntity.ok(empresaService.getAllEmpresas());
    }

    @GetMapping("/{id}/sucursales")
    public ResponseEntity<List<Sucursal>> getSucursalesByEmpresa(@PathVariable("id") Integer id) {
        return ResponseEntity.ok(empresaService.getSucursalesByEmpresa(id));
    }

    @PostMapping("/sucursales")
    public ResponseEntity<Sucursal> createSucursal(@Valid @RequestBody SucursalRequest request) {
        return ResponseEntity.ok(empresaService.createSucursal(request));
    }

    @GetMapping("/sucursales")
    public ResponseEntity<List<Sucursal>> getAllSucursales() {
        return ResponseEntity.ok(empresaService.getAllSucursales());
    }

    @PutMapping("/{id}")
    public ResponseEntity<Empresa> updateEmpresa(@PathVariable("id") Integer id,
            @Valid @RequestBody EmpresaRequest request) {
        return ResponseEntity.ok(empresaService.updateEmpresa(id, request));
    }
}
