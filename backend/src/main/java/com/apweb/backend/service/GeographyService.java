package com.apweb.backend.service;

import com.apweb.backend.model.Canton;
import com.apweb.backend.model.Ciudad;
import com.apweb.backend.model.Pais;
import com.apweb.backend.repository.CantonRepository;
import com.apweb.backend.repository.CiudadRepository;
import com.apweb.backend.repository.PaisRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class GeographyService {

    private final PaisRepository paisRepository;
    private final CiudadRepository ciudadRepository;
    private final CantonRepository cantonRepository;

    public GeographyService(PaisRepository paisRepository,
                            CiudadRepository ciudadRepository,
                            CantonRepository cantonRepository) {
        this.paisRepository = paisRepository;
        this.ciudadRepository = ciudadRepository;
        this.cantonRepository = cantonRepository;
    }

    @Transactional(readOnly = true)
    public List<Pais> getAllPaises() {
        return paisRepository.findAll();
    }

    @Transactional(readOnly = true)
    public List<Ciudad> getCiudadesByPaisId(Integer paisId) {
        return ciudadRepository.findByPais_Id(paisId);
    }

    @Transactional(readOnly = true)
    public List<Canton> getCantonesByCiudadId(Integer ciudadId) {
        return cantonRepository.findByCiudad_Id(ciudadId);
    }
}
