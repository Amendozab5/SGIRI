package com.apweb.backend.repository;

import com.apweb.backend.model.Ciudad;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface CiudadRepository extends JpaRepository<Ciudad, Integer> {
    List<Ciudad> findByPais_Id(Integer paisId);
}
