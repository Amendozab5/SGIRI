package com.apweb.backend.service;

import com.apweb.backend.model.*;
import com.apweb.backend.repository.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.time.LocalDateTime;
import java.util.UUID;

@Service
public class ContractService {

    @Autowired
    private EmpresaRepository empresaRepository;

    @Autowired
    private DocumentoEmpresaRepository documentoEmpresaRepository;

    @Autowired
    private TipoDocumentoRepository tipoDocumentoRepository;

    @Autowired
    private CatalogoItemRepository catalogoItemRepository;

    @Autowired
    private FileStorageService fileStorageService;

    @Transactional
    public Empresa processContractUpload(MultipartFile file) {
        // 1. Save file
        String fileName = fileStorageService.save(file, "contracts");

        // 2. Simulated extraction (Mock)
        // From "Contrato_Netlife_2024.pdf" we extract "Netlife"
        String originalName = file.getOriginalFilename();
        String extractedName = "Empresa desde Contrato";

        if (originalName != null && originalName.contains("_")) {
            String[] parts = originalName.split("_");
            if (parts.length > 1) {
                extractedName = parts[1].replace(".pdf", "").replace(".docx", "");
            }
        }

        // Check for duplicates
        if (empresaRepository.findByNombreComercial(extractedName).isPresent()) {
            throw new RuntimeException("Error: La empresa '" + extractedName + "' ya se encuentra registrada.");
        }

        String extractedRuc = "99" + (long) (Math.random() * 100000000L) + "001";

        // 3. Create Empresa
        Empresa empresa = new Empresa();
        empresa.setNombreComercial(extractedName);
        empresa.setRazonSocial(extractedName + " S.A.");
        empresa.setRuc(extractedRuc);
        empresa.setTipoEmpresa("PRIVADA");
        empresa.setFechaCreacion(LocalDateTime.now());

        CatalogoItem estadoActivo = catalogoItemRepository.findByCatalogo_NombreAndCodigo("ESTADOS_GENERALES", "ACTIVO")
                .orElse(null);
        empresa.setEstado(estadoActivo);

        empresa = empresaRepository.save(empresa);

        // 4. Create DocumentoEmpresa
        // Look for a type that might fit, or use 'CONTRATO' if it exists.
        // If not, we'll just try to find one or a default.
        TipoDocumento tipoContrato = tipoDocumentoRepository.findByCodigo("CONTRATO")
                .orElseGet(() -> {
                    return tipoDocumentoRepository.findAll().stream().findFirst().orElse(null);
                });

        DocumentoEmpresa doc = new DocumentoEmpresa();
        doc.setEmpresa(empresa);
        doc.setNumeroDocumento("CONT-" + UUID.randomUUID().toString().substring(0, 8));
        doc.setRutaArchivo(fileName);
        doc.setDescripcion("Contrato legal cargado automáticamente");
        doc.setTipoDocumento(tipoContrato);
        doc.setEstado(estadoActivo);

        documentoEmpresaRepository.save(doc);

        return empresa;
    }
}
