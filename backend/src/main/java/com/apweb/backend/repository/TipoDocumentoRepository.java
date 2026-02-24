package com.apweb.backend.repository;

import com.apweb.backend.model.TipoDocumento;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface TipoDocumentoRepository extends JpaRepository<TipoDocumento, Integer> {
    Optional<TipoDocumento> findByCodigo(String codigo);
}
