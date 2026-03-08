export interface AuditTimeline {
    eventKey: string;
    tipoEntidad: string;
    fecha: string; // ISO format from backend
    modulo: string;
    accion: string;
    descripcion: string;
    actor?: string; // Nombre humano
    idUsuario?: number;
    usuarioBd?: string;
    ipOrigen?: string;
    exito: boolean;
    tablaAfectada?: string;
}

export interface AuditDetail extends AuditTimeline {
    userAgent?: string;
    endpoint?: string;
    metodoHttp?: string;
    valoresAnteriores?: any;
    valoresNuevos?: any;
    observacion?: string;
    idTicket?: number;
    estadoAnterior?: string;
    estadoNuevo?: string;
}

export interface AuditTimelineResponse {
    content: AuditTimeline[];
    totalElements: number;
    totalPages: number;
    size: number;
    number: number;
}
