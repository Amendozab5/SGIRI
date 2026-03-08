package com.apweb.backend.repositories.notificaciones;

import com.apweb.backend.models.entities.notificaciones.NotificacionesColaCorreo;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface NotificacionesColaCorreoRepository extends JpaRepository<NotificacionesColaCorreo, Integer> {

    List<NotificacionesColaCorreo> findByEnviadoFalse();
}
