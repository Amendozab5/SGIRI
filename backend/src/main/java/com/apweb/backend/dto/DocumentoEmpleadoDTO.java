package com.apweb.backend.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import com.fasterxml.jackson.annotation.JsonFormat;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DocumentoEmpleadoDTO {

    private Integer idDocumento;
    private String numeroDocumento;
    private String rutaArchivo;
    private String descripcion;
    @JsonFormat(shape = JsonFormat.Shape.STRING, pattern = "yyyy-MM-dd'T'HH:mm:ss")
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
