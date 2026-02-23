export interface Persona {
    id: number;
    cedula: string;
    nombre: string;
    apellido: string;
    celular: string;
    correo: string;
    fechaNacimiento: string;
    direccion: string;
}

export interface Empleado {
    id: number;
    persona: Persona;
    fechaIngreso: string;
    cargo: any;
    area: any;
    tiposSugeridos?: string[];
}

export interface Cliente {
    id: number;
    persona: Persona;
    sucursal: any;
    accesoRemoto: boolean;
}
