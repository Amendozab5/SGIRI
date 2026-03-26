package com.apweb.backend.repository;

import com.apweb.backend.model.ConfiguracionBackup;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface ConfiguracionBackupRepository extends JpaRepository<ConfiguracionBackup, Integer> {
    
    // Solo suele haber una configuración global, pero devolvemos la última
    Optional<ConfiguracionBackup> findFirstByOrderByIdDesc();
}
