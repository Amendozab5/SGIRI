package com.apweb.backend.service;

import com.apweb.backend.model.Cliente;
import com.apweb.backend.model.Empleado;
import com.apweb.backend.model.Persona;
import com.apweb.backend.repository.ClienteRepository;
import com.apweb.backend.repository.EmpleadoRepository;
import com.apweb.backend.repository.PersonaRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
public class PersonnelService {

    @Autowired
    private PersonaRepository personaRepository;

    @Autowired
    private EmpleadoRepository empleadoRepository;

    @Autowired
    private ClienteRepository clienteRepository;

    public List<Persona> getAllPersonas() {
        return personaRepository.findAll();
    }

    public List<Empleado> getAllEmpleados() {
        return empleadoRepository.findAll();
    }

    public List<Cliente> getAllClientes() {
        return clienteRepository.findAll();
    }

    public Optional<Empleado> getEmpleadoByCedula(String cedula) {
        return empleadoRepository.findByPersona_Cedula(cedula);
    }

    public Optional<Cliente> getClienteByCedula(String cedula) {
        return clienteRepository.findByPersona_Cedula(cedula);
    }
}
