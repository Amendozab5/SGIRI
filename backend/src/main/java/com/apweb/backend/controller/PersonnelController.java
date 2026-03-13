package com.apweb.backend.controller;

import com.apweb.backend.dto.EmpleadoAccessStatusDTO;
import com.apweb.backend.dto.EmpleadoActivarAccesoRequest;
import com.apweb.backend.dto.EmpleadoCreateRequest;
import com.apweb.backend.dto.EmpleadoDTO;
import com.apweb.backend.model.Cliente;
import com.apweb.backend.model.Persona;
import com.apweb.backend.payload.response.UserAdminView;
import com.apweb.backend.service.PersonnelService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/personnel")
public class PersonnelController {

    @Autowired
    private PersonnelService personnelService;

    // ─── Personas ─────────────────────────────────────────────────────────────

    @GetMapping("/personas")
    @PreAuthorize("hasRole('ADMIN_MASTER') or hasRole('ADMIN_TECNICOS')")
    public List<Persona> getAllPersonas() {
        return personnelService.getAllPersonas();
    }

    // ─── Empleados ────────────────────────────────────────────────────────────

    @GetMapping("/empleados")
    @PreAuthorize("hasRole('ADMIN_MASTER') or hasRole('ADMIN_TECNICOS')")
    public List<EmpleadoDTO> getAllEmpleados() {
        return personnelService.getAllEmpleados();
    }

    @GetMapping("/empleados/{cedula}")
    @PreAuthorize("hasRole('ADMIN_MASTER') or hasRole('ADMIN_TECNICOS')")
    public ResponseEntity<EmpleadoDTO> getEmpleado(@PathVariable(name = "cedula") String cedula) {
        return personnelService.getEmpleadoByCedula(cedula)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    /**
     * Crea el registro laboral de un empleado.
     * Si la persona (cédula) no existe en usuarios.persona, también la crea.
     * Si ya existe como persona pero no como empleado, reutiliza la persona.
     * No crea usuario del sistema — eso es un paso posterior explícito.
     */
    @PostMapping("/empleados")
    @PreAuthorize("hasRole('ADMIN_MASTER') or hasRole('ADMIN_TECNICOS')")
    public ResponseEntity<EmpleadoDTO> crearEmpleado(@Valid @RequestBody EmpleadoCreateRequest request) {
        EmpleadoDTO creado = personnelService.crearEmpleado(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(creado);
    }

    /**
     * Verifica si un empleado cumple todas las condiciones para habilitar acceso.
     * El frontend usa esta respuesta para mostrar el estado correcto en la UI
     * antes de intentar crear el usuario del sistema.
     */
    @GetMapping("/empleados/{cedula}/acceso-status")
    @PreAuthorize("hasRole('ADMIN_MASTER') or hasRole('ADMIN_TECNICOS')")
    public ResponseEntity<EmpleadoAccessStatusDTO> getAccessStatus(@PathVariable(name = "cedula") String cedula) {
        return ResponseEntity.ok(personnelService.getAccessStatus(cedula));
    }

    /**
     * Habilita el acceso al sistema para un empleado existente.
     *
     * <p>
     * Endpoint exclusivo para el dominio de empleados. No requiere username ni
     * password ya que éstos son generados automáticamente por
     * {@code usuarios.fn_crear_usuario_empleado(...)}.
     * </p>
     *
     * <p>
     * Precondiciones que valida la función SQL:
     * <ul>
     * <li>La cédula existe en usuarios.persona + empleados.empleado</li>
     * <li>El empleado tiene al menos un documento con estado ACTIVO</li>
     * <li>No existe ya un usuario del sistema para ese empleado</li>
     * </ul>
     * </p>
     *
     * @param cedula  Cédula del empleado (path variable)
     * @param request Datos de activación: rol, idEmpresa, anioNacimiento
     */
    @PostMapping("/empleados/{cedula}/activar-acceso")
    @PreAuthorize("hasRole('ADMIN_MASTER') or hasRole('ADMIN_TECNICOS')")
    public ResponseEntity<UserAdminView> activarAccesoEmpleado(
            @PathVariable(name = "cedula") String cedula,
            @Valid @RequestBody EmpleadoActivarAccesoRequest request) {
        UserAdminView result = personnelService.activarAccesoEmpleado(cedula, request);
        return ResponseEntity.status(HttpStatus.CREATED).body(result);
    }

    // ─── Clientes ─────────────────────────────────────────────────────────────

    @GetMapping("/clientes")
    @PreAuthorize("hasRole('ADMIN_MASTER') or hasRole('ADMIN_TECNICOS')")
    public List<Cliente> getAllClientes() {
        return personnelService.getAllClientes();
    }

    @GetMapping("/clientes/{cedula}")
    @PreAuthorize("hasRole('ADMIN_MASTER') or hasRole('ADMIN_TECNICOS')")
    public ResponseEntity<Cliente> getCliente(@PathVariable(name = "cedula") String cedula) {
        return personnelService.getClienteByCedula(cedula)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }
}
