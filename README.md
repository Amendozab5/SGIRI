# SGIRI - Sistema de Gestión de Incidencias

Este proyecto es un sistema de gestión de incidencias que consta de un backend desarrollado en Spring Boot y un frontend en Angular.

## 🚀 Requisitos Previos

Antes de comenzar, asegúrate de tener instalado lo siguiente:
* [Java 17](https://www.oracle.com/java/technologies/javase/jdk17-archive-downloads.html)
* [Node.js](https://nodejs.org/) (versión LTS recomendada)
* [PostgreSQL](https://www.postgresql.org/)
* [Angular CLI](https://angular.io/cli) (opcional, se puede usar `npm`)

---

## 🛠️ Configuración del Backend (Spring Boot)

El backend utiliza **Spring Boot 3.2.1** y **Maven**.

### 1. Base de Datos
1. Abre tu cliente de PostgreSQL (pgAdmin o terminal).
2. Crea una base de datos llamada `SGIM2`.
3. Verifica la configuración en `backend/src/main/resources/application.properties`:
   ```properties
   spring.datasource.url=jdbc:postgresql://localhost:5432/SGIM2
   spring.datasource.username=tu_usuario
   spring.datasource.password=tu_contraseña
   ```

### 2. Ejecución
Navega a la carpeta del backend y ejecuta el siguiente comando:
```bash
cd backend
./mvnw spring-boot:run
```
El servidor se iniciará en: `http://localhost:8081`

---

## 💻 Configuración del Frontend (Angular)

El frontend está desarrollado en **Angular**.

### 1. Instalación de Dependencias
Navega a la carpeta del frontend e instala los paquetes necesarios:
```bash
cd frontend
npm install
```

### 2. Ejecución
Inicia el servidor de desarrollo:
```bash
npm start
```
La aplicación estará disponible en: `http://localhost:4200`

---

## 📁 Estructura del Proyecto

* `/backend`: Código fuente de la API REST, seguridad (JWT) y persistencia.
* `/frontend`: Interfaz de usuario, componentes y servicios de Angular.
* `/SQL`: Scripts de base de datos (si los hay).
* `/documentation`: Documentación adicional del proyecto.

## 👥 Contribuidores
* **Amendozab5** - *Desarrollo Inicial*
