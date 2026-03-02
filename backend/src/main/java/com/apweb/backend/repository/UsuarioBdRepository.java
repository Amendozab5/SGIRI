package com.apweb.backend.repository;

import com.apweb.backend.model.UsuarioBd;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface UsuarioBdRepository extends JpaRepository<UsuarioBd, Integer> {
    List<UsuarioBd> findByUser_Id(Integer idUsuario);
}
