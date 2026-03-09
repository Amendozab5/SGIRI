package com.apweb.backend.repository;

import com.apweb.backend.model.VwSlaTecnico;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface VwSlaTecnicoRepository extends JpaRepository<VwSlaTecnico, Integer> {
}
