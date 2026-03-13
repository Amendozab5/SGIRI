import { Component, EventEmitter, Input, OnInit, Output, ViewChild, ElementRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormBuilder, FormGroup, ReactiveFormsModule, Validators } from '@angular/forms';
import { Modal } from 'bootstrap';
import { TicketService } from '../../_services/ticket.service';
import { UserService } from '../../_services/user.service';
import { TokenStorageService } from '../../_services/token-storage.service';
import { VisitaTecnica, VisitaRequest } from '../../models/visita';
import { Ticket } from '../../models/ticket';
import { UserAdminView } from '../../models/user-admin-view.model';

@Component({
    selector: 'app-visita-form-modal',
    templateUrl: './visita-form-modal.component.html',
    styleUrls: ['./visita-form-modal.component.css'],
    standalone: true,
    imports: [CommonModule, ReactiveFormsModule]
})
export class VisitaFormModalComponent implements OnInit {
    @Input() tickets: Ticket[] = [];
    @Input() tecnicos: UserAdminView[] = [];
    @Input() allVisitas: VisitaTecnica[] = [];

    @Output() save = new EventEmitter<{ request: VisitaRequest, id: number | null }>();

    @ViewChild('visitaModal') modalElement!: ElementRef;
    private modalInstance?: Modal;

    visitaForm: FormGroup;
    isEditMode = false;
    currentVisitaId: number | null = null;
    isLocked = false;
    isTechnicianAutoSelected = false;
    conflictInfo: any = null;
    isTechnician = false;
    currentTicket: Ticket | null = null;

    constructor(
        private fb: FormBuilder,
        private ticketService: TicketService,
        private userService: UserService,
        private tokenService: TokenStorageService
    ) {
        this.visitaForm = this.fb.group({
            idTicket: ['', Validators.required],
            idTecnico: ['', Validators.required],
            fechaVisita: ['', Validators.required],
            horaInicio: ['', Validators.required],
            horaFin: [''],
            codigoEstado: ['PROGRAMADA', Validators.required],
            reporteVisita: ['']
        });
    }

    ngOnInit(): void {
        this.visitaForm.get('idTicket')?.valueChanges.subscribe(id => {
            const selectedTicket = this.tickets.find(t => t.idTicket == id);
            if (selectedTicket && selectedTicket.usuarioAsignado) {
                this.visitaForm.patchValue({ idTecnico: selectedTicket.usuarioAsignado.id }, { emitEvent: true });
                this.isTechnicianAutoSelected = true;
            } else {
                this.isTechnicianAutoSelected = false;
            }
            this.checkConflicts();
        });

        this.visitaForm.valueChanges.subscribe(() => {
            this.checkConflicts();
        });
    }

    checkConflicts(): void {
        const { idTecnico, fechaVisita, horaInicio, horaFin } = this.visitaForm.getRawValue();
        if (!idTecnico || !fechaVisita || !horaInicio) {
            this.conflictInfo = null;
            return;
        }

        const start = this.timeToMinutes(horaInicio);
        const end = horaFin ? this.timeToMinutes(horaFin) : start + 60;

        const conflict = this.allVisitas.find(v => {
            if (this.isEditMode && v.idVisita === this.currentVisitaId) return false;
            if (v.tecnico.id != idTecnico || v.fechaVisita !== fechaVisita) return false;
            if (['CANCELADA'].includes(v.estado.codigo)) return false;

            const vStart = this.timeToMinutes(v.horaInicio);
            const vEnd = v.horaFin ? this.timeToMinutes(v.horaFin) : vStart + 60;

            return (start < vEnd) && (end > vStart);
        });

        this.conflictInfo = conflict ? {
            ticket: conflict.ticket.idTicket,
            time: conflict.horaInicio.substring(0, 5),
            endTime: conflict.horaFin?.substring(0, 5) || '??'
        } : null;
    }

    private timeToMinutes(time: string): number {
        const [h, m] = time.split(':').map(Number);
        return h * 60 + m;
    }

    getAutoSelectedTechnicianName(): string {
        const idTicket = this.visitaForm.get('idTicket')?.value;
        let ticket = this.tickets.find(t => t.idTicket == idTicket);

        // Fallback al ticket de la visita actual si no está en la lista de pendientes
        if (!ticket && this.currentTicket && this.currentTicket.idTicket == idTicket) {
            ticket = this.currentTicket;
        }

        if (ticket && ticket.usuarioAsignado) {
            const u = ticket.usuarioAsignado;
            // Priorizamos nombre y apellido si están disponibles (gracias al FETCH en el backend)
            if (u.persona && (u.persona.nombre || u.persona.apellido)) {
                return `${u.persona.nombre || ''} ${u.persona.apellido || ''}`.trim();
            }
            if (u.nombre || u.apellidos) {
                return `${u.nombre || ''} ${u.apellidos || ''}`.trim();
            }
            return u.fullName || u.username || 'Técnico asignado';
        }

        return 'Seleccione un ticket primero...';
    }

    ngAfterViewInit(): void {
        this.modalInstance = new Modal(this.modalElement.nativeElement);
    }

    open(visita?: VisitaTecnica, initialDate?: string, idTicket?: number): void {
        this.visitaForm.reset({ codigoEstado: 'PROGRAMADA' });
        this.isLocked = false;
        this.isTechnicianAutoSelected = false;

        const user = this.tokenService.getUser();
        this.isTechnician = user?.roles.includes('ROLE_TECNICO') || false;

        this.visitaForm.enable();

        // Controlamos el estado del campo técnico
        if (this.isTechnician || this.isLocked) {
            this.visitaForm.get('idTecnico')?.disable();
        } else {
            this.visitaForm.get('idTecnico')?.enable();
        }

        if (visita) {
            this.isEditMode = true;
            this.isTechnicianAutoSelected = true;
            this.currentVisitaId = visita.idVisita || null;
            this.visitaForm.patchValue({
                idTicket: visita.ticket.idTicket,
                idTecnico: visita.tecnico.id,
                fechaVisita: visita.fechaVisita,
                horaInicio: visita.horaInicio,
                horaFin: visita.horaFin,
                idEmpresa: visita.empresa.id,
                codigoEstado: visita.estado.codigo,
                reporteVisita: visita.reporteVisita
            });

            this.currentTicket = visita.ticket;

            const ticketStatus = visita.ticket.estadoItem?.codigo;
            if (['FINALIZADA', 'CANCELADA'].includes(visita.estado.codigo) ||
                ['CERRADO', 'RESUELTO'].includes(ticketStatus || '')) {
                this.isLocked = true;
                this.visitaForm.disable();
            }
        } else {
            this.isEditMode = false;
            this.currentVisitaId = null;
            if (initialDate) {
                this.visitaForm.patchValue({ fechaVisita: initialDate });
            }
            if (idTicket) {
                this.visitaForm.patchValue({ idTicket: idTicket });
            }
        }

        if (this.isTechnician) {
            this.isLocked = true;
            this.visitaForm.disable();
        }

        this.modalInstance?.show();
    }

    hide(): void {
        this.modalInstance?.hide();
    }

    getSelectedTicket(): Ticket | undefined {
        const id = this.visitaForm.get('idTicket')?.value;
        const ticketFromList = this.tickets.find(t => t.idTicket == id);
        if (ticketFromList) return ticketFromList;

        // Si no está en la lista de pendientes (ej: ya tiene visita), usar el guardado al abrir el modal
        if (this.currentTicket && this.currentTicket.idTicket == id) {
            return this.currentTicket;
        }
        return undefined;
    }

    getGoogleMapsUrl(address: string | undefined): string {
        if (!address) return '#';
        return `https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(address)}`;
    }

    reprogramar(): void {
        this.isLocked = false;
        this.visitaForm.enable();
        this.visitaForm.patchValue({ codigoEstado: 'REPROGRAMADA' });
    }

    onSubmit(): void {
        if (this.visitaForm.valid) {
            const formValue = this.visitaForm.getRawValue(); // getRawValue para obtener campos disabled
            const currentUser = this.tokenService.getUser();
            const idEmpresa = currentUser?.idEmpresa || 1;

            const request: VisitaRequest = {
                ...formValue,
                idEmpresa: idEmpresa
            };

            this.save.emit({ request, id: this.currentVisitaId });
        }
    }
}
