import { User } from './user.model';

export interface Ticket {
    idTicket?: number;
    cedulaCliente: string;
    idCategoria: number;
    idPrioridad: number;
    idEstado: number;
    asunto: string;
    descripcion: string;
    fechaCreacion?: Date;
    fechaActualizacion?: Date;
    idServicio: number;
    idSucursal: number;
    idSla?: number;
    idEstadoItem?: number;
    idPrioridadItem?: number;
    idCategoriaItem: number;
    usuarioCreador?: User;
    idUsuarioAsignado?: number;
    idEmpresa: number;
    idCliente: number;
    idEmpleado: number;
}
