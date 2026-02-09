package com.apweb.backend.payload.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class TicketRequest {

    @NotBlank
    private String cedulaCliente;

    @NotNull
    private Integer idCategoria;

    @NotNull
    private Integer idPrioridad;

    @NotNull
    private Integer idEstado; // This maps to id_estado in ticket table

    @NotBlank
    private String asunto;

    @NotBlank
    private String descripcion;

    @NotNull
    private Integer idServicio;

    @NotNull
    private Integer idSucursal;

    private Integer idSla; // Optional

    private Integer idEstadoItem; // Optional

    private Integer idPrioridadItem; // Optional

    @NotNull
    private Integer idCategoriaItem;

    private Integer idUsuarioAsignado; // Optional

    @NotNull
    private Integer idEmpresa;

    @NotNull
    private Integer idCliente;

    @NotNull
    private Integer idEmpleado;
}
