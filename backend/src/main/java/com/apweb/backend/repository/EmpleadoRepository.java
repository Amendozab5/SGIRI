package com.apweb.backend.repository;

import com.apweb.backend.model.Empleado;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.Optional;
import java.util.List;

@Repository
public interface EmpleadoRepository extends JpaRepository<Empleado, Integer> {
    Optional<Empleado> findByPersona_Correo(String correo);

    Boolean existsByPersona_Correo(String correo);

    Boolean existsByPersona_Cedula(String cedula);

    Optional<Empleado> findByPersona_Cedula(String cedula);

    @org.springframework.data.jpa.repository.Query("SELECT e FROM Empleado e " +
            "LEFT JOIN FETCH e.persona p " +
            "LEFT JOIN FETCH p.user u " +
            "LEFT JOIN FETCH u.role r " +
            "LEFT JOIN FETCH e.cargo c " +
            "LEFT JOIN FETCH e.area a " +
            "LEFT JOIN FETCH e.tipoContrato tc")
    List<Empleado> findAllWithAllAssociations();

    Optional<Empleado> findByPersona_User_Id(Integer userId);
}
