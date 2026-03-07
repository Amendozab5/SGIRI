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
public class DocumentoEmpleadoDTO {

    private Integer idDocumento;
    private String numeroDocumento;
    private String rutaArchivo;
    private String descripcion;
    private LocalDateTime fechaSubida;

    // Tipo de documento
    private Integer idTipoDocumento;
    private String codigoTipoDocumento;
    private String nombreTipoDocumento;

    // Estado del documento (desde catalogos.catalogo_item)
    private Integer idEstado;
    private String codigoEstado;
    private String nombreEstado;

    // Referencia al empleado
    private Integer idEmpleado;
    private String cedulaEmpleado;
}
