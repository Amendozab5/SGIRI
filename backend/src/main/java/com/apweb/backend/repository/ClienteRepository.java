package com.apweb.backend.repository;

import com.apweb.backend.model.Cliente;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.Optional;

@Repository
public interface ClienteRepository extends JpaRepository<Cliente, Integer> {
    Optional<Cliente> findByPersona_Correo(String correo);

    Boolean existsByPersona_Correo(String correo);

    Optional<Cliente> findByPersona_Cedula(String cedula);

    Boolean existsByPersona_Cedula(String cedula);

    Optional<Cliente> findByPersona_User(com.apweb.backend.model.User user);
}
