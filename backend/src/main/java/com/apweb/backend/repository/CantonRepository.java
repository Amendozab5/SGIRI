package com.apweb.backend.repository;

import com.apweb.backend.model.Canton;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface CantonRepository extends JpaRepository<Canton, Integer> {
    List<Canton> findByCiudad_Id(Integer ciudadId);
}
