package com.apweb.backend.repository;

import com.apweb.backend.model.RegistroBackup;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface RegistroBackupRepository extends JpaRepository<RegistroBackup, Integer> {
    
    // Devolvemos el historial ordenado por fecha descendente
    List<RegistroBackup> findAllByOrderByFechaDesc();
}
