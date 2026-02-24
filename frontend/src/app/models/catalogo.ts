export interface CatalogoItem {
    id: number;
    codigo: string;
    nombre: string;
    orden: number;
    activo: boolean;
}

export interface Catalogo {
    id: number;
    nombre: string;
    descripcion: string;
    activo: boolean;
    items?: CatalogoItem[];
}
