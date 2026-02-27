import { Ticket } from './ticket';
import { User } from './user.model';
import { Empresa } from './empresa';
import { CatalogoItem } from './catalogo';

export interface VisitaTecnica {
    idVisita?: number;
    ticket: Ticket;
    tecnico: User;
    empresa: Empresa;
    fechaVisita: string; // ISO Date YYYY-MM-DD
    horaInicio: string; // HH:mm:ss
    horaFin?: string;
    estado: CatalogoItem;
    reporteVisita?: string;
}

export interface VisitaRequest {
    idTicket: number;
    idTecnico: number;
    idEmpresa: number;
    fechaVisita: string;
    horaInicio: string;
    horaFin?: string;
    codigoEstado: string;
    reporteVisita?: string;
}
