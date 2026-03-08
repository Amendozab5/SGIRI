export interface NotificacionWeb {
    id: number;
    titulo: string;
    mensaje: string;
    rutaRedireccion: string;
    idTicket?: number;
    leida: boolean;
    fechaCreacion: string;
}
