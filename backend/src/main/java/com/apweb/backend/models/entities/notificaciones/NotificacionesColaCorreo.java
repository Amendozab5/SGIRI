package com.apweb.backend.models.entities.notificaciones;

import com.apweb.backend.model.Empresa;
import com.apweb.backend.model.Ticket;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDateTime;

@Entity
@Table(name = "cola_correo", schema = "notificaciones")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class NotificacionesColaCorreo {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_correo")
    private Integer id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id_empresa", nullable = false)
    private Empresa empresa;

    @Column(name = "destinatario_correo", nullable = false, length = 150)
    private String destinatario;

    @Column(nullable = false, length = 200)
    private String asunto;

    @Column(name = "cuerpo_html", nullable = false, columnDefinition = "TEXT")
    private String cuerpoHtml;

    @Builder.Default
    @Column(nullable = false)
    private Boolean enviado = false;

    @Builder.Default
    @Column(nullable = false)
    private Integer intentos = 0;

    @Column(name = "fecha_creacion")
    private LocalDateTime fechaCreacion;

    @Column(name = "fecha_envio")
    private LocalDateTime fechaEnvio;

    @Column(name = "error_envio", columnDefinition = "TEXT")
    private String errorEnvio;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id_ticket")
    private Ticket ticket;

    @PrePersist
    protected void onCreate() {
        fechaCreacion = LocalDateTime.now();
    }
}
