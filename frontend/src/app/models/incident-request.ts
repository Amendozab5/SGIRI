export interface IncidentRequest {
  asunto: string;
  descripcion: string;
  idSucursal: number;
  idServicio: number;
  idEstadoItem: number;
  idPrioridadItem: number;
  idCategoriaItem: number;
  idEmpresa: number;
  idCliente: number;
  idEmpleado: number;
  cedulaCliente: string;
}
