package com.apweb.backend.service;

import com.apweb.backend.model.*;
import com.apweb.backend.repository.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;
import java.util.Optional;

@Service
public class DocumentService {

    private final EmpleadoRepository empleadoRepository;
    private final ClienteRepository clienteRepository;
    private final DocumentoEmpleadoRepository documentoEmpleadoRepository;
    private final DocumentoClienteRepository documentoClienteRepository;
    private final TipoDocumentoRepository tipoDocumentoRepository;
    private final FileStorageService fileStorageService;
    private final UserRepository userRepository;

    public DocumentService(EmpleadoRepository empleadoRepository,
            ClienteRepository clienteRepository,
            DocumentoEmpleadoRepository documentoEmpleadoRepository,
            DocumentoClienteRepository documentoClienteRepository,
            TipoDocumentoRepository tipoDocumentoRepository,
            FileStorageService fileStorageService,
            UserRepository userRepository) {
        this.empleadoRepository = empleadoRepository;
        this.clienteRepository = clienteRepository;
        this.documentoEmpleadoRepository = documentoEmpleadoRepository;
        this.documentoClienteRepository = documentoClienteRepository;
        this.tipoDocumentoRepository = tipoDocumentoRepository;
        this.fileStorageService = fileStorageService;
        this.userRepository = userRepository;
    }

    @Transactional
    public void uploadProfilePicture(String username, MultipartFile file) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("Usuario no encontrado."));

        Persona persona = user.getPersona();
        if (persona == null) {
            throw new RuntimeException("No se encontró información personal.");
        }

        // We assume the type code is 'FOTO' or similar. Let's use 'FOTO_PERFIL' or just
        // 'FOTO'
        TipoDocumento tipoDoc = tipoDocumentoRepository.findByCodigo("FOTO")
                .orElseThrow(() -> new RuntimeException("Tipo de documento 'FOTO' no encontrado en el catálogo."));

        String fileName = fileStorageService.save(file, username);

        // Check if user is Empleado
        Optional<Empleado> empleadoOpt = empleadoRepository.findByPersona_Cedula(persona.getCedula());
        if (empleadoOpt.isPresent()) {
            Empleado empleado = empleadoOpt.get();
            DocumentoEmpleado doc = documentoEmpleadoRepository
                    .findByEmpleado_IdEmpleadoAndTipoDocumento_Codigo(empleado.getIdEmpleado(), "FOTO")
                    .orElse(new DocumentoEmpleado());

            doc.setEmpleado(empleado);
            doc.setTipoDocumento(tipoDoc);
            doc.setRutaArchivo(fileName);
            doc.setCedulaEmpleado(persona.getCedula());
            doc.setDescripcion("Foto de perfil");
            documentoEmpleadoRepository.save(doc);
            return;
        }

        // Check if user is Cliente
        Optional<Cliente> clienteOpt = clienteRepository.findByPersona_Cedula(persona.getCedula());
        if (clienteOpt.isPresent()) {
            Cliente cliente = clienteOpt.get();
            DocumentoCliente doc = documentoClienteRepository
                    .findByCliente_IdClienteAndTipoDocumento_Codigo(cliente.getIdCliente(), "FOTO")
                    .orElse(new DocumentoCliente());

            doc.setCliente(cliente);
            doc.setTipoDocumento(tipoDoc);
            doc.setRutaArchivo(fileName);
            doc.setNumeroDocumento(persona.getCedula());
            doc.setDescripcion("Foto de perfil");
            documentoClienteRepository.save(doc);
            return;
        }

        throw new RuntimeException("El usuario no está registrado como Empleado o Cliente para asignar documentos.");
    }

    @Transactional(readOnly = true)
    public String getProfilePictureFilename(String username) {
        User user = userRepository.findByUsername(username).orElse(null);
        if (user == null || user.getPersona() == null) {
            return null;
        }

        Persona persona = user.getPersona();

        // Check Empleado
        Optional<Empleado> empleadoOpt = empleadoRepository.findByPersona_Cedula(persona.getCedula());
        if (empleadoOpt.isPresent()) {
            Optional<DocumentoEmpleado> doc = documentoEmpleadoRepository
                    .findByEmpleado_IdEmpleadoAndTipoDocumento_Codigo(empleadoOpt.get().getIdEmpleado(), "FOTO");
            if (doc.isPresent()) {
                return doc.get().getRutaArchivo();
            }
        }

        // Check Cliente
        Optional<Cliente> clienteOpt = clienteRepository.findByPersona_Cedula(persona.getCedula());
        if (clienteOpt.isPresent()) {
            Optional<DocumentoCliente> doc = documentoClienteRepository
                    .findByCliente_IdClienteAndTipoDocumento_Codigo(clienteOpt.get().getIdCliente(), "FOTO");
            if (doc.isPresent()) {
                return doc.get().getRutaArchivo();
            }
        }

        return null; // Not found
    }
}
