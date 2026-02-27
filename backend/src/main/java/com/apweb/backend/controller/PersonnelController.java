package com.apweb.backend.controller;

import com.apweb.backend.model.Cliente;
import com.apweb.backend.model.Empleado;
import com.apweb.backend.model.Persona;
import com.apweb.backend.service.PersonnelService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@CrossOrigin(origins = "http://localhost:4200", maxAge = 3600, allowCredentials = "true")
@RestController
@RequestMapping("/api/personnel")
public class PersonnelController {

    @Autowired
    private PersonnelService personnelService;

    @GetMapping("/personas")
    public List<Persona> getAllPersonas() {
        return personnelService.getAllPersonas();
    }

    @GetMapping("/empleados")
    public List<Empleado> getAllEmpleados() {
        return personnelService.getAllEmpleados();
    }

    @GetMapping("/clientes")
    public List<Cliente> getAllClientes() {
        return personnelService.getAllClientes();
    }

    @GetMapping("/empleados/{cedula}")
    public ResponseEntity<Empleado> getEmpleado(@PathVariable("cedula") String cedula) {
        return personnelService.getEmpleadoByCedula(cedula)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @GetMapping("/clientes/{cedula}")
    public ResponseEntity<Cliente> getCliente(@PathVariable("cedula") String cedula) {
        return personnelService.getClienteByCedula(cedula)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }
}
