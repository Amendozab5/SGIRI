import { CatalogoItem } from './catalogo';

export interface Empresa {
  id: number;
  nombreComercial: string;
  razonSocial: string;
  ruc: string;
  tipoEmpresa: string;
  correoContacto?: string;
  telefonoContacto?: string;
  direccionPrincipal?: string;
  estado?: CatalogoItem; // Link to CatalogoItem object
  fechaCreacion?: string;
}
