package com.apweb.backend.repository;

import com.apweb.backend.model.TipoContrato;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface TipoContratoRepository extends JpaRepository<TipoContrato, Integer> {
}
