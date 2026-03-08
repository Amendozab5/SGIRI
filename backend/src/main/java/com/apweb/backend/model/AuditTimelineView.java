package com.apweb.backend.model;

import jakarta.persistence.*;
import lombok.Data;
import org.hibernate.annotations.Immutable;

import java.time.LocalDateTime;

/**
 * Entidad JPA mapeada a la vista SQL {@code auditoria.vw_timeline_administrativa}.
 * Se marca como {@code @Immutable} ya que es una vista de solo lectura.
 */
@Entity
@Immutable
@Table(name = "vw_timeline_administrativa", schema = "auditoria")
@Data
public class AuditTimelineView {

    @Id
    @Column(name = "event_key")
    private String eventKey;

    @Column(name = "tipo_entidad")
    private String tipoEntidad;

    @Column(name = "original_id")
    private Integer originalId;

    @Column(name = "fecha")
    private LocalDateTime fecha;

    @Column(name = "modulo")
    private String modulo;

    @Column(name = "accion")
    private String accion;

    @Column(name = "descripcion")
    private String descripcion;

    @Column(name = "id_usuario")
    private Integer idUsuario;

    @Column(name = "actor")
    private String actor;

    @Column(name = "usuario_bd")
    private String usuarioBd;

    @Column(name = "ip_origen")
    private String ipOrigen;

    @Column(name = "exito")
    private Boolean exito;

    @Column(name = "tabla_afectada")
    private String tablaAfectada;
}
