import {
  Component,
  AfterViewInit,
  ElementRef,
  ViewChild,
  Output,
  EventEmitter,
  HostListener,
  OnDestroy,
  Input
} from '@angular/core';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-signature-pad',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './signature-pad.component.html',
  styleUrls: ['./signature-pad.component.css']
})
export class SignaturePadComponent implements AfterViewInit, OnDestroy {
  @Input() title: string = 'Firma del Cliente';
  @Input() subtitle: string = 'El cliente debe firmar en el área de abajo para confirmar el servicio recibido';
  @Input() confirmLabel: string = 'Generar Hoja de Servicio';
  @ViewChild('signatureCanvas') canvasRef!: ElementRef<HTMLCanvasElement>;
  @Output() firmaConfirmada = new EventEmitter<Blob>();
  @Output() cancelled = new EventEmitter<void>();

  private ctx!: CanvasRenderingContext2D;
  private isDrawing = false;
  private lastX = 0;
  private lastY = 0;
  isEmpty = true;

  ngAfterViewInit() {
    const canvas = this.canvasRef.nativeElement;
    this.ctx = canvas.getContext('2d')!;
    this.resizeCanvas();
    this.setDrawingStyle();
  }

  ngOnDestroy() {}

  private resizeCanvas() {
    const canvas = this.canvasRef.nativeElement;
    const container = canvas.parentElement!;
    canvas.width = container.clientWidth || 600;
    canvas.height = 220;
    this.setDrawingStyle();
  }

  private setDrawingStyle() {
    this.ctx.lineWidth = 2.5;
    this.ctx.lineCap = 'round';
    this.ctx.lineJoin = 'round';
    this.ctx.strokeStyle = '#1e2a4a';
  }

  // ─── Mouse events ────────────────────────────────────────────────────────
  onMouseDown(e: MouseEvent) {
    this.isDrawing = true;
    const { x, y } = this.getPos(e);
    this.lastX = x;
    this.lastY = y;
  }

  onMouseMove(e: MouseEvent) {
    if (!this.isDrawing) return;
    e.preventDefault();
    this.draw(this.getPos(e));
  }

  onMouseUp() { this.isDrawing = false; }
  onMouseLeave() { this.isDrawing = false; }

  // ─── Touch events ────────────────────────────────────────────────────────
  onTouchStart(e: TouchEvent) {
    e.preventDefault();
    this.isDrawing = true;
    const { x, y } = this.getTouchPos(e);
    this.lastX = x;
    this.lastY = y;
  }

  onTouchMove(e: TouchEvent) {
    if (!this.isDrawing) return;
    e.preventDefault();
    this.draw(this.getTouchPos(e));
  }

  onTouchEnd() { this.isDrawing = false; }

  // ─── Drawing logic ───────────────────────────────────────────────────────
  private draw(pos: { x: number; y: number }) {
    this.ctx.beginPath();
    this.ctx.moveTo(this.lastX, this.lastY);
    this.ctx.lineTo(pos.x, pos.y);
    this.ctx.stroke();
    this.lastX = pos.x;
    this.lastY = pos.y;
    this.isEmpty = false;
  }

  private getPos(e: MouseEvent): { x: number; y: number } {
    const rect = this.canvasRef.nativeElement.getBoundingClientRect();
    return { x: e.clientX - rect.left, y: e.clientY - rect.top };
  }

  private getTouchPos(e: TouchEvent): { x: number; y: number } {
    const rect = this.canvasRef.nativeElement.getBoundingClientRect();
    const touch = e.touches[0];
    return { x: touch.clientX - rect.left, y: touch.clientY - rect.top };
  }

  // ─── Actions ─────────────────────────────────────────────────────────────
  limpiar() {
    const canvas = this.canvasRef.nativeElement;
    this.ctx.clearRect(0, 0, canvas.width, canvas.height);
    this.isEmpty = true;
  }

  confirmar() {
    if (this.isEmpty) return;
    const canvas = this.canvasRef.nativeElement;
    canvas.toBlob((blob) => {
      if (blob) this.firmaConfirmada.emit(blob);
    }, 'image/png');
  }

  cancelar() {
    this.cancelled.emit();
  }
}
