import { Component, OnInit, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { MasterDataService } from '../../_services/master-data.service';
import { Catalogo, CatalogoItem } from '../../models/catalogo';
import { finalize } from 'rxjs/operators';

@Component({
    selector: 'app-catalog-management',
    standalone: true,
    imports: [CommonModule, FormsModule],
    templateUrl: './catalog-management.component.html',
    styleUrls: ['./catalog-management.component.css']
})
export class CatalogManagementComponent implements OnInit {
    catalogos: Catalogo[] = [];
    selectedCatalogo: Catalogo | null = null;
    loading = false;
    error = '';
    showItemModal = false;
    savingItem = false;
    newItem = {
        nombre: '',
        codigo: '',
        orden: 1,
        activo: true
    };

    constructor(
        private masterDataService: MasterDataService,
        private cdr: ChangeDetectorRef
    ) { }

    ngOnInit(): void {
        this.loadCatalogos();
    }

    loadCatalogos(): void {
        this.loading = true;
        this.error = '';
        this.masterDataService.getCatalogos()
            .pipe(finalize(() => {
                this.loading = false;
                this.cdr.detectChanges();
            }))
            .subscribe({
                next: (data) => {
                    this.catalogos = data;
                },
                error: (err) => {
                    this.error = 'Error al cargar los catálogos';
                }
            });
    }

    selectCatalogo(catalogo: Catalogo): void {
        this.selectedCatalogo = catalogo;
        this.loading = true;
        this.masterDataService.getCatalogoItems(catalogo.nombre)
            .pipe(finalize(() => {
                this.loading = false;
                this.cdr.detectChanges();
            }))
            .subscribe({
                next: (items) => {
                    this.selectedCatalogo!.items = items;
                },
                error: (err) => {
                    this.error = 'Error al cargar los items del catálogo';
                }
            });
    }

    toggleStatus(item: CatalogoItem): void {
        this.masterDataService.toggleItemStatus(item.id).subscribe({
            next: (updatedItem) => {
                item.activo = updatedItem.activo;
                this.cdr.detectChanges();
            },
            error: (err) => {
                console.error('Error toggling status:', err);
                alert('No se pudo cambiar el estado del item');
            }
        });
    }

    openItemModal(): void {
        this.newItem = {
            nombre: '',
            codigo: '',
            orden: (this.selectedCatalogo?.items?.length || 0) + 1,
            activo: true
        };
        this.showItemModal = true;
    }

    saveItem(): void {
        if (!this.selectedCatalogo) return;

        this.savingItem = true;
        this.masterDataService.createCatalogoItem(this.selectedCatalogo.id, this.newItem)
            .pipe(finalize(() => {
                this.savingItem = false;
                this.cdr.detectChanges();
            }))
            .subscribe({
                next: (createdItem) => {
                    if (!this.selectedCatalogo!.items) {
                        this.selectedCatalogo!.items = [];
                    }
                    this.selectedCatalogo!.items.push(createdItem);
                    this.showItemModal = false;
                },
                error: (err) => {
                    console.error('Error saving item:', err);
                    alert('Error al crear el elemento en el catálogo');
                }
            });
    }
}
