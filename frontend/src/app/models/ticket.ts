import { User } from './user.model';
import { CatalogoItem } from './catalogo';
import { Sucursal } from './sucursal';
import { Servicio } from './servicio';

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

    // Nested objects from backend
    estadoItem?: CatalogoItem;
    prioridadItem?: CatalogoItem;
    categoriaItem?: CatalogoItem;
    sucursal?: Sucursal;
    servicio?: Servicio;

    usuarioCreador?: User;
    usuarioAsignado?: User;
    idUsuarioAsignado?: number;
    idEmpresa: number;
    idCliente: number;
    idEmpleado: number;

    cliente?: Cliente;
    comentarios?: Comentario[];
    historialEstados?: HistorialEstado[];
}

export interface Cliente {
    idCliente: number;
    persona?: Persona;
}

export interface Persona {
    idPersona: number;
    cedula: string;
    nombre: string;
    apellido: string;
    celular?: string;
    correo?: string;
    direccion?: string;
}

export interface Comentario {
    idComentario: number;
    usuario: User;
    comentario: string;
    fechaCreacion: Date;
    esInterno: boolean;
}

export interface HistorialEstado {
    idHistorial: number;
    estado?: CatalogoItem;
    fechaCambio: Date;
    observacion: string;
    usuario: User;
}
