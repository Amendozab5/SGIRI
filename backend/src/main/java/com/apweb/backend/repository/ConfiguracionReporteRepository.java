package com.apweb.backend.repository;

import com.apweb.backend.model.ConfiguracionReporte;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;

public interface ConfiguracionReporteRepository extends JpaRepository<ConfiguracionReporte, Integer> {
    Optional<ConfiguracionReporte> findByCodigoUnico(String codigoUnico);
}
