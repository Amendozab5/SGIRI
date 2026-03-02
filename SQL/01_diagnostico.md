# A) Diagnóstico de Modelo de Datos Geográficos y Tickets

Tras analizar el esquema de base de datos PostgreSQL (`SGIM2.sql`), he identificado lo siguiente respecto al modelo geográfico y su relación con usuarios y tickets:

### 1. ¿Qué campos dictaminan la "Ubicación" en Cliente / Persona / Usuario?
*   **`usuarios.persona`**: Tiene únicamente la columna `id_canton`. No tiene un enlace directo a la provincia (`ciudad`), asumiendo que la jerarquía (Cantón -> Ciudad -> País) se respeta en la capa de datos.
*   **`empresa.sucursal`**: Tiene ambas relaciones explícitas: `id_ciudad` (Provincia) y `id_canton` (Cantón). 
*   **`clientes.cliente`**: **No almacena datos geográficos directamente**. Un cliente es una relación puramente de negocio que amarra apuntando a un `id_persona` (quién es) y un `id_sucursal` (dónde está su base o contrato principal).
*   **`usuarios.usuario`**: **Tampoco almacena ubicación directamente**. Un usuario está enlazado a una `persona` a través del campo `id_usuario` presente en la tabla `persona`.

### 2. Relación directa con Tickets
*   **`soporte.ticket`**: Contiene `id_cliente` e `id_sucursal`.
*   **La "Fuente de Verdad" Geográfica del Ticket**: Es el cruce `ticket -> sucursal`. El sistema depende del `id_sucursal` registrado en el ticket para posicionar la incidencia en el mapa `Network Map`. El campo `id_ciudad` (Provincia) dentro de `empresa.sucursal` es el que realmente alimenta los reportes provinciales. Si un ticket apunta a una sucursal que carece de `id_ciudad`, este se vuelve "ciego" geográficamente.

### Conclusión del Diagnóstico
La arquitectura actual exige que para que el flujo de Tickets en el **Network Map** no se rompa o quede vacío (fallback a gris):
1. Las Personas deben estar insertadas apuntando a un Cantón.
2. Los Clientes deben estar enlazados a estas Personas pero, **más importante aún**, a **Sucursales que obligatoriamente tengan `id_ciudad` e `id_canton` completados**.
3. Al aperturar un Ticket, el `id_sucursal` amarrado debe ser válido y heredar la ubicación de la tabla `sucursal`.
