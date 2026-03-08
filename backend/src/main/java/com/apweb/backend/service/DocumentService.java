package com.apweb.backend.service;

import com.apweb.backend.dto.DocumentoEmpleadoDTO;
import com.apweb.backend.model.*;
import com.apweb.backend.repository.*;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

import com.apweb.backend.service.AuditService;
import com.apweb.backend.util.AuditAccion;
import com.apweb.backend.util.AuditModulo;

@Service
public class DocumentService {

    private static final Logger log = LoggerFactory.getLogger(DocumentService.class);

    private final EmpleadoRepository empleadoRepository;
    private final ClienteRepository clienteRepository;
    private final DocumentoEmpleadoRepository documentoEmpleadoRepository;
    private final DocumentoClienteRepository documentoClienteRepository;
    private final TipoDocumentoRepository tipoDocumentoRepository;
    private final CatalogoItemRepository catalogoItemRepository;
    private final FileStorageService fileStorageService;
    private final UserRepository userRepository;
    private final AuditService auditService;

    public DocumentService(EmpleadoRepository empleadoRepository,
            ClienteRepository clienteRepository,
            DocumentoEmpleadoRepository documentoEmpleadoRepository,
            DocumentoClienteRepository documentoClienteRepository,
            TipoDocumentoRepository tipoDocumentoRepository,
            CatalogoItemRepository catalogoItemRepository,
            FileStorageService fileStorageService,
            UserRepository userRepository,
            AuditService auditService) {
        this.empleadoRepository = empleadoRepository;
        this.clienteRepository = clienteRepository;
        this.documentoEmpleadoRepository = documentoEmpleadoRepository;
        this.documentoClienteRepository = documentoClienteRepository;
        this.tipoDocumentoRepository = tipoDocumentoRepository;
        this.catalogoItemRepository = catalogoItemRepository;
        this.fileStorageService = fileStorageService;
        this.userRepository = userRepository;
        this.auditService = auditService;
    }

    // ─── Foto de perfil (lógica preexistente intacta) ─────────────────────────

    @Transactional
    public void uploadProfilePicture(String username, MultipartFile file) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("Usuario no encontrado."));

        Persona persona = user.getPersona();
        if (persona == null) {
            throw new RuntimeException("No se encontró información personal.");
        }

        TipoDocumento tipoDoc = tipoDocumentoRepository.findByCodigo("FOTO")
                .orElseThrow(() -> new RuntimeException(
                        "Tipo de documento 'FOTO' no encontrado en el catálogo."));

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

            // ── AUDITORÍA: Foto Perfil Empleado ──────────────────────────────────
            auditService.registrarEventoContextual(
                    AuditModulo.PERFIL,
                    "empleados", "documento_empleado",
                    empleado.getIdEmpleado(),
                    AuditAccion.UPLOAD_DOCUMENTO,
                    "Carga de foto de perfil (Empleado)",
                    null,
                    java.util.Map.of("unique_filename", fileName)
            );
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

            // ── AUDITORÍA: Foto Perfil Cliente ───────────────────────────────────
            auditService.registrarEventoContextual(
                    AuditModulo.PERFIL,
                    "catalogos", "documento_cliente",
                    cliente.getIdCliente(),
                    AuditAccion.UPLOAD_DOCUMENTO,
                    "Carga de foto de perfil (Cliente)",
                    null,
                    java.util.Map.of("unique_filename", fileName)
            );
            return;
        }

        throw new RuntimeException(
                "El usuario no está registrado como Empleado o Cliente para asignar documentos.");
    }

    @Transactional(readOnly = true)
    public String getProfilePictureFilename(String username) {
        User user = userRepository.findByUsername(username).orElse(null);
        if (user == null || user.getPersona() == null) return null;

        Persona persona = user.getPersona();

        Optional<Empleado> empleadoOpt = empleadoRepository.findByPersona_Cedula(persona.getCedula());
        if (empleadoOpt.isPresent()) {
            Optional<DocumentoEmpleado> doc = documentoEmpleadoRepository
                    .findByEmpleado_IdEmpleadoAndTipoDocumento_Codigo(
                            empleadoOpt.get().getIdEmpleado(), "FOTO");
            if (doc.isPresent()) return doc.get().getRutaArchivo();
        }

        Optional<Cliente> clienteOpt = clienteRepository.findByPersona_Cedula(persona.getCedula());
        if (clienteOpt.isPresent()) {
            Optional<DocumentoCliente> doc = documentoClienteRepository
                    .findByCliente_IdClienteAndTipoDocumento_Codigo(
                            clienteOpt.get().getIdCliente(), "FOTO");
            if (doc.isPresent()) return doc.get().getRutaArchivo();
        }

        return null;
    }

    // ─── Gestión documental de empleados ─────────────────────────────────────

    /**
     * Lista todos los documentos laborales de un empleado (excluye FOTO).
     */
    @Transactional(readOnly = true)
    public List<DocumentoEmpleadoDTO> getDocumentosEmpleado(Integer idEmpleado) {
        empleadoRepository.findById(idEmpleado)
                .orElseThrow(() -> new IllegalArgumentException(
                        "No existe un empleado con id=" + idEmpleado));

        return documentoEmpleadoRepository.findByEmpleado_IdEmpleado(idEmpleado)
                .stream()
                .filter(d -> d.getTipoDocumento() == null
                        || !"FOTO".equals(d.getTipoDocumento().getCodigo()))
                .map(this::toDocumentoDTO)
                .collect(Collectors.toList());
    }

    /**
     * Sube un documento laboral al empleado.
     * Estado inicial: PENDIENTE — requiere validación admin antes de habilitar acceso.
     * El {@code idTipoDocumento} es opcional; si no se proporciona se omite el tipo.
     */
    @Transactional
    public DocumentoEmpleadoDTO subirDocumentoEmpleado(
            Integer idEmpleado,
            MultipartFile file,
            Integer idTipoDocumento,
            String numeroDocumento,
            String descripcion) {

        if (file == null || file.isEmpty()) {
            throw new IllegalArgumentException("Debe seleccionar un archivo para subir.");
        }

        Empleado empleado = empleadoRepository.findById(idEmpleado)
                .orElseThrow(() -> new IllegalArgumentException(
                        "No existe un empleado con id=" + idEmpleado));

        // Tipo de documento — es opcional; si no se envía queda nulo en BD
        TipoDocumento tipoDoc = null;
        if (idTipoDocumento != null) {
            tipoDoc = tipoDocumentoRepository.findById(idTipoDocumento)
                    .orElseThrow(() -> new IllegalArgumentException(
                            "No existe un tipo de documento con id=" + idTipoDocumento));
        }

        // Estado inicial PENDIENTE — garantiza que el admin revise antes de activar acceso
        CatalogoItem estadoPendiente = catalogoItemRepository.findFirstByCodigo("PENDIENTE")
                .orElseThrow(() -> new RuntimeException(
                        "Estado 'PENDIENTE' no encontrado en catálogos. Verifique los datos maestros."));

        String cedula = (empleado.getPersona() != null) ? empleado.getPersona().getCedula() : "";
        String fileName = fileStorageService.save(file, "emp_doc_" + idEmpleado);

        DocumentoEmpleado doc = new DocumentoEmpleado();
        doc.setEmpleado(empleado);
        doc.setTipoDocumento(tipoDoc);   // puede ser null si no se seleccionó
        doc.setRutaArchivo(fileName);
        doc.setCedulaEmpleado(cedula);
        doc.setNumeroDocumento(numeroDocumento != null ? numeroDocumento.trim() : "");
        doc.setDescripcion(descripcion != null ? descripcion.trim() : "");
        doc.setEstado(estadoPendiente);

        DocumentoEmpleado guardado = documentoEmpleadoRepository.save(doc);
        
        // ── AUDITORÍA: Carga de Documento Laboral ────────────────────────────
        auditService.registrarEventoContextual(
                AuditModulo.DOCUMENTOS,
                "empleados", "documento_empleado",
                guardado.getIdDocumento(),
                AuditAccion.UPLOAD_DOCUMENTO,
                "Carga de documento tipo: " + (tipoDoc != null ? tipoDoc.getCodigo() : "SIN TIPO"),
                null,
                java.util.Map.of(
                    "id_empleado", idEmpleado,
                    "tipo_codigo", tipoDoc != null ? tipoDoc.getCodigo() : "NULL",
                    "id_estado", estadoPendiente.getId()
                )
        );
        // ────────────────────────────────────────────────────────────────────

        log.info("[DOCS-EMPLEADO] Documento subido — empleadoId={}, tipo={}, estado=PENDIENTE",
                idEmpleado, tipoDoc != null ? tipoDoc.getCodigo() : "(sin tipo)");

        return toDocumentoDTO(guardado);
    }

    /**
     * Cambia el estado de un documento de empleado.
     * Estados válidos: ACTIVO, PENDIENTE, RECHAZADO.
     * Cuando pasa a ACTIVO el empleado (si aún no tiene usuario) queda apto para acceso.
     */
    @Transactional
    public DocumentoEmpleadoDTO cambiarEstadoDocumento(Integer idDocumento, String codigoEstado) {
        DocumentoEmpleado doc = documentoEmpleadoRepository.findById(idDocumento)
                .orElseThrow(() -> new IllegalArgumentException(
                        "No existe un documento con id=" + idDocumento));

        List<String> estadosValidos = List.of("ACTIVO", "PENDIENTE", "RECHAZADO");
        String estadoNormalizado = codigoEstado.toUpperCase();
        if (!estadosValidos.contains(estadoNormalizado)) {
            throw new IllegalArgumentException(
                    "Estado no válido: '" + codigoEstado + "'. Valores permitidos: ACTIVO, PENDIENTE, RECHAZADO.");
        }

        CatalogoItem nuevoEstado = catalogoItemRepository.findFirstByCodigo(estadoNormalizado)
                .orElseThrow(() -> new RuntimeException(
                        "Estado '" + estadoNormalizado + "' no encontrado en el catálogo."));

        doc.setEstado(nuevoEstado);
        DocumentoEmpleado actualizado = documentoEmpleadoRepository.save(doc);

        // ── AUDITORÍA: Cambio de Estado Documento ────────────────────────────
        auditService.registrarEventoContextual(
                AuditModulo.DOCUMENTOS,
                "empleados", "documento_empleado",
                actualizado.getIdDocumento(),
                AuditAccion.CAMBIO_ESTADO_DOC,
                "Gestión administrativa de documento: " + estadoNormalizado,
                null,
                java.util.Map.of(
                    "id_empleado", actualizado.getEmpleado() != null ? actualizado.getEmpleado().getIdEmpleado() : "NULL",
                    "nuevo_estado", estadoNormalizado
                )
        );
        // ────────────────────────────────────────────────────────────────────

        log.info("[DOCS-EMPLEADO] Estado del documento id={} cambiado a {}", idDocumento, estadoNormalizado);
        return toDocumentoDTO(actualizado);
    }

    // ─── Tipos de documento (para dropdowns) ──────────────────────────────────

    /**
     * Devuelve todos los tipos de documento disponibles (excluye FOTO).
     * Usado por el frontend para el selector del formulario de subida.
     */
    @Transactional(readOnly = true)
    public List<TipoDocumento> getTiposDocumento() {
        return tipoDocumentoRepository.findAll().stream()
                .filter(t -> !"FOTO".equalsIgnoreCase(t.getCodigo()))
                .collect(Collectors.toList());
    }

    // ─── Helpers ─────────────────────────────────────────────────────────────

    private DocumentoEmpleadoDTO toDocumentoDTO(DocumentoEmpleado d) {
        CatalogoItem estado = d.getEstado();
        TipoDocumento tipo = d.getTipoDocumento();
        Empleado emp = d.getEmpleado();

        return DocumentoEmpleadoDTO.builder()
                .idDocumento(d.getIdDocumento())
                .numeroDocumento(d.getNumeroDocumento())
                .rutaArchivo(d.getRutaArchivo())
                .descripcion(d.getDescripcion())
                .fechaSubida(d.getFechaSubida())
                .idTipoDocumento(tipo != null ? tipo.getId() : null)
                .codigoTipoDocumento(tipo != null ? tipo.getCodigo() : null)
                .nombreTipoDocumento(tipo != null ? tipo.getCodigo() : null)
                .idEstado(estado != null ? estado.getId() : null)
                .codigoEstado(estado != null ? estado.getCodigo() : null)
                .nombreEstado(estado != null ? estado.getNombre() : null)
                .idEmpleado(emp != null ? emp.getIdEmpleado() : null)
                .cedulaEmpleado(d.getCedulaEmpleado())
                .build();
    }
}
