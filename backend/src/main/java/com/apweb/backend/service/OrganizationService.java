package com.apweb.backend.service;

import com.apweb.backend.model.Area;
import com.apweb.backend.model.Cargo;
import com.apweb.backend.model.TipoContrato;
import com.apweb.backend.repository.AreaRepository;
import com.apweb.backend.repository.CargoRepository;
import com.apweb.backend.repository.TipoContratoRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class OrganizationService {

    @Autowired
    private AreaRepository areaRepository;

    @Autowired
    private CargoRepository cargoRepository;

    @Autowired
    private TipoContratoRepository tipoContratoRepository;

    public List<Area> getAllAreas() {
        return areaRepository.findAll();
    }

    public List<Cargo> getAllCargos() {
        return cargoRepository.findAll();
    }

    public List<TipoContrato> getAllTiposContrato() {
        return tipoContratoRepository.findAll();
    }
}
