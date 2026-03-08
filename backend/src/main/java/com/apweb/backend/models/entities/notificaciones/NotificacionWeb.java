package com.apweb.backend.models.entities.notificaciones;

import com.apweb.backend.model.Empresa;
import com.apweb.backend.model.Ticket;
import com.apweb.backend.model.User;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDateTime;

@Entity
@Table(name = "notificacion_web", schema = "notificaciones")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@org.hibernate.annotations.DynamicUpdate
public class NotificacionWeb {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_notificacion")
    private Integer id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id_usuario_destino", nullable = false)
    private User usuarioDestino;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id_empresa", nullable = false)
    private Empresa empresa;

    @Column(nullable = false, length = 150)
    private String titulo;

    @Column(nullable = false, columnDefinition = "TEXT")
    private String mensaje;

    @Column(name = "ruta_redireccion", nullable = false, length = 255)
    private String rutaRedireccion;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id_ticket")
    private Ticket ticket;

    @Builder.Default
    @Column(nullable = false)
    private Boolean leida = false;

    @Column(name = "fecha_creacion")
    private LocalDateTime fechaCreacion;

    @Column(name = "fecha_lectura")
    private LocalDateTime fechaLectura;

    @PrePersist
    protected void onCreate() {
        fechaCreacion = LocalDateTime.now();
    }
}
