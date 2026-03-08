package com.apweb.backend.repositories.notificaciones;

import com.apweb.backend.models.entities.notificaciones.NotificacionWeb;
import com.apweb.backend.model.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface NotificacionWebRepository extends JpaRepository<NotificacionWeb, Integer> {

    List<NotificacionWeb> findByUsuarioDestinoOrderByFechaCreacionDesc(User usuario);

    long countByUsuarioDestinoAndLeidaFalse(User usuario);
}
