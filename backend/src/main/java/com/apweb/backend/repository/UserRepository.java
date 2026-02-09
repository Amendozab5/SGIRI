package com.apweb.backend.repository;

import com.apweb.backend.model.Role; // Import Role
import com.apweb.backend.model.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List; // Import List
import java.util.Optional;

@Repository
public interface UserRepository extends JpaRepository<User, Integer> {
    Optional<User> findByUsername(String username);
    Boolean existsByUsername(String username);
    List<User> findByRole(Role role); // New method
    
    @Query(value = "SELECT usuarios.generar_username_unico(:nombres, :apellidos)", nativeQuery = true)
    String generarUsernameUnico(@Param("nombres") String nombres, @Param("apellidos") String apellidos);
    @Query("SELECT u FROM User u LEFT JOIN FETCH u.usuarioCliente WHERE u.id = :id")
    Optional<User> findByIdWithUsuarioCliente(@Param("id") Integer id);
    Optional<User> findByResetPasswordToken(String token);
}
