package com.apweb.backend.service;

import com.apweb.backend.model.Catalogo;
import com.apweb.backend.model.CatalogoItem;
import com.apweb.backend.repository.CatalogoItemRepository;
import com.apweb.backend.repository.CatalogoRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.Collections;
import java.util.List;

@Service
public class CatalogoService {

    @Autowired
    private CatalogoRepository catalogoRepository;

    @Autowired
    private CatalogoItemRepository catalogoItemRepository;

    public List<CatalogoItem> getItemsByCatalogoNombre(String nombre) {
        return catalogoRepository.findByNombre(nombre)
                .map(Catalogo::getItems)
                .orElse(Collections.emptyList());
    }

    public List<Catalogo> getAllCatalogos() {
        return catalogoRepository.findAll();
    }

    public Catalogo getCatalogoById(Integer id) {
        return catalogoRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Catálogo no encontrado"));
    }

    public CatalogoItem saveItem(CatalogoItem item) {
        return catalogoItemRepository.save(item);
    }

    public CatalogoItem toggleItemStatus(Integer id) {
        CatalogoItem item = catalogoItemRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Item no encontrado"));
        item.setActivo(!item.getActivo());
        return catalogoItemRepository.save(item);
    }
}
