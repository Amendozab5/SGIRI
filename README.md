# SGIRI – Sistema de Gestión de Incidencias de Red de Internet

SGIRI es un sistema web desarrollado como proyecto académico para la asignatura **Aplicaciones Web** y **Administración de bases de datos** , cuyo objetivo es la gestión de incidencias relacionadas con servicios de red, integrando un backend robusto y un frontend moderno.

El proyecto está construido bajo una arquitectura cliente-servidor utilizando **Spring Boot** para el backend y **Angular** para el frontend.

---

## Tecnologías utilizadas

### Backend
- Java
- Spring Boot
- Spring Security
- JPA / Hibernate
- PostgreSQL

### Frontend
- Angular
- TypeScript
- Bootstrap

### Otros
- Git & GitHub
- SQL

---

## Funcionalidades implementadas

Actualmente, el proyecto cuenta con las siguientes funcionalidades **operativas**:

### Gestión de usuarios
- Registro de usuarios
- Inicio de sesión con autenticación
- Gestión de roles y permisos
- Actualización de perfil de usuario
- Seguridad mediante JWT

### Maestro de datos
- Administración de catálogos base del sistema
- Gestión de datos maestros como:
  - Países
  - Ciudades
  - Categorías
  - Prioridades
  - Roles
- Uso de catálogos para garantizar consistencia de la información

> ⚠️ Otras funcionalidades del sistema se encuentran en proceso de desarrollo.

---

## 🗂️ Estructura del proyecto

```text
Proyecto APWEB/
│
├── backend/        # Backend Spring Boot
├── frontend/       # Frontend Angular
├── sql-data/       # Scripts SQL y datos iniciales
├── backups/        # Respaldo de la base de datos
├── documentation/ # Documentación del proyecto
├── Logo/           # Recursos gráficos
└── .gitignore
