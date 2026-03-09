package com.apweb.backend.payload.request;

import lombok.Data;

@Data
public class InformeTrabajoTecnicoRequest {

    private String resultado; // "RESUELTO" or "NO_RESUELTO"

    private String implementosUsados;

    private String problemasEncontrados;

    private String solucionAplicada;

    private String pruebasRealizadas;

    private String motivoNoResolucion;

    private String comentarioTecnico;

    private String urlAdjunto;

    private Integer tiempoTrabajoMinutos;

    private java.util.List<ItemUsadoRequest> inventarioItems;

    @Data
    public static class ItemUsadoRequest {
        private Integer idItemInventario;
        private Integer cantidad;
    }
}
