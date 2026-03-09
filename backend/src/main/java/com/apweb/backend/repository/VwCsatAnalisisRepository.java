package com.apweb.backend.repository;

import com.apweb.backend.model.VwCsatAnalisis;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.time.LocalDateTime;

@Repository
public interface VwCsatAnalisisRepository extends JpaRepository<VwCsatAnalisis, LocalDateTime> {
}
