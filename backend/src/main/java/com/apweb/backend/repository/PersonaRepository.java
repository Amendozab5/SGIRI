package com.apweb.backend.repository;

import com.apweb.backend.model.Persona;
import com.apweb.backend.model.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.Optional;

@Repository
public interface PersonaRepository extends JpaRepository<Persona, Integer> {
    Optional<Persona> findByCedula(String cedula);

    Optional<Persona> findByCorreo(String correo);

    Boolean existsByCedula(String cedula);

    Boolean existsByCorreo(String correo);

    Optional<Persona> findByUser(User user);
}
