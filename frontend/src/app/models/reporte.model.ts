export interface ConfiguracionReporte {
    idReporte: number;
    nombre: string;
    descripcion: string;
    codigoUnico: string;
    modulo: string;
    tipoSalida: string;
    esActivo: boolean;
    fechaCreacion: string;
}

export interface TicketResumenReporte {
    idTicket: number;
    asunto: string;
    fechaCreacion: string;
    fechaCierre?: string;
    estado?: string;
    estadoCodigo?: string;
    prioridad?: string;
    tiempoResolucion?: string;
    calificacionSatisfaccion?: number;
    idUsuarioAsignado?: number;
    idCliente: number;
    idSucursal: number;
    idCategoriaItem: number;
    categoria?: string;
}

export interface SlaTecnicoReporte {
    idUsuario: number;
    tecnicoNombre: string;
    totalTickets: number;
    ticketsResueltos: number;
    slaCumplido: number;
    avgResolucionHoras: number;
}

export interface CsatAnalisisReporte {
    mes: string;
    totalRespuestas: number;
    puntajePromedio: number;
    tasaPositiva: number;
}

export interface CsatDetalleReporte {
    idTicket: number;
    asunto: string;
    fechaCreacion: string;
    fechaCierre: string;
    calificacionSatisfaccion: number;
    comentarioCalificacion: string;
    clienteNombre: string;
    categoria: string;
}
