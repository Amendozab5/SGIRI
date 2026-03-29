package com.apweb.backend.repository;

import com.apweb.backend.model.Catalogo;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface CatalogoRepository extends JpaRepository<Catalogo, Integer> {
    Optional<Catalogo> findByNombre(String nombre);

    @org.springframework.data.jpa.repository.Query("SELECT DISTINCT c FROM Catalogo c LEFT JOIN FETCH c.items")
    java.util.List<Catalogo> findAllWithItems();
}
