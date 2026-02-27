package com.apweb.backend.controller;

import com.apweb.backend.model.Catalogo;
import com.apweb.backend.model.CatalogoItem;
import com.apweb.backend.service.CatalogoService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@CrossOrigin(origins = "http://localhost:4200", maxAge = 3600, allowCredentials = "true")
@RestController
@RequestMapping("/api/catalogos")
public class CatalogoController {

    @Autowired
    private CatalogoService catalogoService;

    @GetMapping
    public List<Catalogo> getAllCatalogos() {
        return catalogoService.getAllCatalogos();
    }

    @GetMapping("/{nombre}/items")
    public List<CatalogoItem> getItemsByCatalogo(
            @PathVariable("nombre") String nombre,
            @RequestParam(name = "onlyActive", defaultValue = "false") boolean onlyActive) {
        return catalogoService.getItemsByCatalogoNombre(nombre, onlyActive);
    }

    @PutMapping("/items/{id}/toggle-status")
    public ResponseEntity<?> toggleItemStatus(@PathVariable("id") Integer id) {
        return ResponseEntity.ok(catalogoService.toggleItemStatus(id));
    }

    @PostMapping("/{catalogoId}/items")
    public ResponseEntity<?> createItem(@PathVariable("catalogoId") Integer catalogoId,
            @RequestBody CatalogoItem item) {
        Catalogo catalogo = catalogoService.getCatalogoById(catalogoId);
        item.setCatalogo(catalogo);
        if (item.getActivo() == null)
            item.setActivo(true);
        return ResponseEntity.ok(catalogoService.saveItem(item));
    }
}
