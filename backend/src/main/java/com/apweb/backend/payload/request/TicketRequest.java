package com.apweb.backend.payload.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class TicketRequest {

    private String cedulaCliente;

    @NotBlank
    private String asunto;

    @NotBlank
    private String descripcion;

    @NotNull
    private Integer idCategoriaItem;

    @NotNull
    private Integer idSucursal;

    private Integer idServicio;

    // Optional fields for technicians/admins
    private Integer idPrioridadItem;
    private Integer idEstadoItem;
    private Integer idSla;
    private Integer idUsuarioAsignado;
    private Integer idEmpresa;
    private Integer idCliente;
    private Integer idEmpleado;
}
