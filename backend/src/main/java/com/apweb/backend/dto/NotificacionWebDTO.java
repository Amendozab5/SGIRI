package com.apweb.backend.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class NotificacionWebDTO {
    private Integer id;
    private String titulo;
    private String mensaje;
    private String rutaRedireccion;
    private Integer idTicket;
    private Boolean leida;
    private LocalDateTime fechaCreacion;
}
