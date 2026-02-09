export interface TicketRequest {
    cedulaCliente: string;
    idCategoria: number;
    idPrioridad: number;
    idEstado: number;
    asunto: string;
    descripcion: string;
    idServicio: number;
    idSucursal: number;
    idSla?: number; // Optional
    idEstadoItem?: number; // Optional
    idPrioridadItem?: number; // Optional
    idCategoriaItem: number;
    idUsuarioAsignado?: number; // Optional
    idEmpresa: number;
    idCliente: number;
    idEmpleado: number;
}
