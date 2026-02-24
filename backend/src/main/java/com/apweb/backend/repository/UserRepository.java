package com.apweb.backend.repository;

import com.apweb.backend.model.Role; // Import Role
import com.apweb.backend.model.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List; // Import List
import java.util.Optional;

@Repository
public interface UserRepository extends JpaRepository<User, Integer> {
    Optional<User> findByUsername(String username);

    Boolean existsByUsername(String username);

    List<User> findByRole(Role role);
}
