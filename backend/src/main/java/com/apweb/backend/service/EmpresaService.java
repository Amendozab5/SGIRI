package com.apweb.backend.service;

import com.apweb.backend.model.Empresa;
import com.apweb.backend.model.Sucursal;
import com.apweb.backend.payload.request.EmpresaRequest;
import com.apweb.backend.payload.request.SucursalRequest;
import com.apweb.backend.repository.CatalogoItemRepository;
import com.apweb.backend.repository.EmpresaRepository;
import com.apweb.backend.repository.SucursalRepository;
import com.apweb.backend.model.CatalogoItem;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;

@Service
public class EmpresaService {

    @Autowired
    private EmpresaRepository empresaRepository;

    @Autowired
    private SucursalRepository sucursalRepository;

    @Autowired
    private CatalogoItemRepository catalogoItemRepository;

    public List<Empresa> getAllEmpresas() {
        return empresaRepository.findAll();
    }

    public Empresa createEmpresa(EmpresaRequest request) {
        Empresa empresa = new Empresa();
        empresa.setNombreComercial(request.getNombreComercial());
        empresa.setRazonSocial(request.getRazonSocial());
        empresa.setRuc(request.getRuc());
        empresa.setTipoEmpresa(request.getTipoEmpresa());
        empresa.setCorreoContacto(request.getCorreoContacto());
        empresa.setTelefonoContacto(request.getTelefonoContacto());
        empresa.setFechaCreacion(LocalDateTime.now());

        // Default status ACTIVA
        CatalogoItem estado = catalogoItemRepository.findByCatalogo_NombreAndCodigo("ESTADOS_GENERALES", "ACTIVO")
                .orElse(null);
        empresa.setEstado(estado);

        return empresaRepository.save(empresa);
    }

    public List<Sucursal> getSucursalesByEmpresa(Integer idEmpresa) {
        return sucursalRepository.findByEmpresaId(idEmpresa);
    }

    public Sucursal createSucursal(SucursalRequest request) {
        Empresa empresa = empresaRepository.findById(request.getIdEmpresa())
                .orElseThrow(
                        () -> new RuntimeException("Error: Empresa no encontrada con ID: " + request.getIdEmpresa()));

        Sucursal sucursal = new Sucursal();
        sucursal.setEmpresa(empresa);
        sucursal.setNombre(request.getNombre());
        sucursal.setDireccion(request.getDireccion());
        sucursal.setTelefono(request.getTelefono());
        sucursal.setIdCiudad(request.getIdCiudad());
        sucursal.setIdCanton(request.getIdCanton());

        // Default status ACTIVA
        CatalogoItem estado = catalogoItemRepository.findByCatalogo_NombreAndCodigo("ESTADOS_GENERALES", "ACTIVO")
                .orElse(null);
        sucursal.setEstado(estado);

        return sucursalRepository.save(sucursal);
    }

    public List<Sucursal> getAllSucursales() {
        return sucursalRepository.findAll();
    }
}
