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

    @Output() save = new EventEmitter<{ request: VisitaRequest, id: number | null }>();

    @ViewChild('visitaModal') modalElement!: ElementRef;
    private modalInstance?: Modal;

    visitaForm: FormGroup;
    isEditMode = false;
    currentVisitaId: number | null = null;
    isLocked = false;

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

    ngOnInit(): void { }

    ngAfterViewInit(): void {
        this.modalInstance = new Modal(this.modalElement.nativeElement);
    }

    open(visita?: VisitaTecnica, initialDate?: string): void {
        this.visitaForm.reset({ codigoEstado: 'PROGRAMADA' });
        this.isLocked = false;
        this.visitaForm.enable();

        if (visita) {
            this.isEditMode = true;
            this.currentVisitaId = visita.idVisita || null;
            this.visitaForm.patchValue({
                idTicket: visita.ticket.idTicket,
                idTecnico: visita.tecnico.id,
                fechaVisita: visita.fechaVisita,
                horaInicio: visita.horaInicio,
                horaFin: visita.horaFin,
                codigoEstado: visita.estado.codigo,
                reporteVisita: visita.reporteVisita
            });

            if (['FINALIZADA', 'CANCELADA'].includes(visita.estado.codigo)) {
                this.isLocked = true;
                this.visitaForm.disable();
            }
        } else {
            this.isEditMode = false;
            this.currentVisitaId = null;
            if (initialDate) {
                this.visitaForm.patchValue({ fechaVisita: initialDate });
            }
        }

        this.modalInstance?.show();
    }

    hide(): void {
        this.modalInstance?.hide();
    }

    getSelectedTicket(): Ticket | undefined {
        const id = this.visitaForm.get('idTicket')?.value;
        return this.tickets.find(t => t.idTicket == id);
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
