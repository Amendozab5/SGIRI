package com.apweb.backend.repository;

import com.apweb.backend.model.CatalogoItem;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.Optional;

@Repository
public interface CatalogoItemRepository extends JpaRepository<CatalogoItem, Integer> {
    Optional<CatalogoItem> findByCodigo(String codigo);

    Optional<CatalogoItem> findFirstByCodigo(String codigo);

    Optional<CatalogoItem> findByCatalogo_NombreAndCodigo(String catalogoNombre, String codigo);
}
