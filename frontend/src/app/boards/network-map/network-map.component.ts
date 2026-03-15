import { Component, OnInit, OnDestroy, AfterViewInit } from '@angular/core';
import { CommonModule, DecimalPipe, DatePipe } from '@angular/common';
import { HttpClientModule } from '@angular/common/http';
import * as L from 'leaflet';
import { NetworkService, NetworkMapData } from '../../_services/network.service';
import { HttpClient } from '@angular/common/http';
import { Subscription } from 'rxjs';

@Component({
    selector: 'app-network-map',
    standalone: true,
    imports: [CommonModule, HttpClientModule],
    providers: [DecimalPipe, DatePipe],
    templateUrl: './network-map.component.html',
    styleUrls: ['./network-map.component.css']
})
export class NetworkMapComponent implements OnInit, AfterViewInit, OnDestroy {
    private map: L.Map | undefined;
    private geojsonLayer: L.GeoJSON | undefined;

    private networkData: NetworkMapData[] = [];
    private dataMap: Map<string, NetworkMapData> = new Map();

    private aliasMap: Map<string, string> = new Map([
        ['santo domingo de los tsachilas', 'santo domingo'],
        ['zona no delimitada', 'zonas no delimitadas'],
        ['canar', 'canar'],
        ['los rios', 'los rios'],
        ['galapagos', 'galapagos']
    ]);

    private dataSubscription: Subscription | undefined;

    public overallLatency: number = 0;
    public dataSourceStatus: string = '';
    public lastUpdate: string = '';
    public isFullscreen: boolean = false;
    public isLoading: boolean = false;
    public errorLoading: boolean = false;

    constructor(
        private networkService: NetworkService,
        private http: HttpClient
    ) { }

    ngOnInit(): void {
        this.loadGeoJSON();
        this.subscribeToData();
    }

    ngAfterViewInit(): void {
        setTimeout(() => {
            if (this.map) {
                this.map.invalidateSize();
            }
        }, 800);
    }

    ngOnDestroy(): void {
        if (this.dataSubscription) {
            this.dataSubscription.unsubscribe();
        }
    }

    private loadGeoJSON(): void {
        this.http.get(`assets/ecuador.geojson`).subscribe({
            next: (geojsonData: any) => {
                this.initMap(geojsonData);
                if (this.networkData.length > 0) {
                    this.updateMapColors();
                }
            },
            error: (err) => {
                console.error('Error loading GeoJSON', err);
                this.errorLoading = true;
            }
        });
    }

    private subscribeToData(): void {
        this.dataSubscription = this.networkService.networkData$.subscribe(data => {
            if (data && data.length > 0) {
                this.processNetworkData(data);
                this.updateMapColors();
            }
        });

        this.networkService.isLoading$.subscribe(loading => {
            this.isLoading = loading;
        });
    }

    private processNetworkData(data: NetworkMapData[]): void {
        this.networkData = data;
        this.dataMap.clear();
        data.forEach(z => {
            this.dataMap.set(this.normalizeName(z.zoneName), z);
        });

        if (data.length > 0) {
            this.overallLatency = data[0].latencyOverallMs;
            this.dataSourceStatus = data[0].dataSource;
            this.lastUpdate = data[0].lastSuccessfulCheckAt;
        }
    }

    private initMap(geoData?: any): void {
        if (this.map) return;

        this.map = L.map('networkMap', {
            center: [-1.8312, -78.1834],
            zoom: 6,
            zoomControl: false
        });

        L.tileLayer('https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png', {
            attribution: '&copy; <a href="https://carto.com/">CARTO</a>'
        }).addTo(this.map);

        L.control.zoom({ position: 'bottomright' }).addTo(this.map);

        if (geoData) {
            this.handleGeoJSON(geoData);
        }
    }

    private handleGeoJSON(geojsonData: any): void {
        if (this.geojsonLayer && this.map) {
            this.map.removeLayer(this.geojsonLayer);
        }

        this.geojsonLayer = L.geoJSON(geojsonData as any, {
            style: this.getFeatureStyle.bind(this),
            onEachFeature: this.onEachFeature.bind(this)
        });

        if (this.map) {
            this.geojsonLayer.addTo(this.map);
            try {
                const bounds = this.geojsonLayer.getBounds();
                if (bounds.isValid()) {
                    this.map.fitBounds(bounds, { padding: [20, 20] });
                }
            } catch (e) {
                console.warn('Could not fit bounds', e);
            }
        }
    }

    private updateMapColors(): void {
        if (this.geojsonLayer) {
            this.geojsonLayer.setStyle(this.getFeatureStyle.bind(this));
        }
    }

    private normalizeName(v: string): string {
        return (v || '')
            .toLowerCase()
            .normalize('NFD')
            .replace(/[\u0300-\u036f]/g, '')
            .trim();
    }

    private getLevelFromScore(score: number): 'GOOD' | 'WARNING' | 'CRITICAL' {
        if (score < 50) return 'CRITICAL';
        if (score < 80) return 'WARNING';
        return 'GOOD';
    }

    private resolveBackendKeyFromGeoKey(geoKey: string): string {
        if (this.dataMap.has(geoKey)) {
            return geoKey;
        }
        const alias = this.aliasMap.get(geoKey);
        return alias ? alias : geoKey;
    }

    private getGeoInfo(feature: any): { geoName: string, data: NetworkMapData | undefined } {
        const props: any = feature?.properties || {};
        const geoName =
            props.dpa_despro || props.DPA_DESPRO ||
            props.nombre || props.NOMBRE ||
            props.name || props.NAME_1 || props.NAME ||
            props.provincia || props.PROVINCIA || '';

        const geoKey = this.normalizeName(geoName);
        const backendKey = this.resolveBackendKeyFromGeoKey(geoKey);
        const data = this.dataMap.get(backendKey);

        return { geoName, data };
    }

    private getFeatureStyle(feature: any): any {
        const { data } = this.getGeoInfo(feature);

        if (data) {
            let fillColor = '#cccccc';
            const score = Number(data.scoreFinal ?? data.scoreTickets ?? 0);
            const level = this.getLevelFromScore(score);

            if (level === 'CRITICAL') fillColor = '#dc3545';
            else if (level === 'WARNING') fillColor = '#ffc107';
            else if (level === 'GOOD') fillColor = '#28a745';

            return {
                fillColor: fillColor,
                weight: 2,
                opacity: 1,
                color: 'white',
                fillOpacity: 0.7
            };
        } else {
            return {
                fillColor: '#cccccc',
                weight: 1,
                opacity: 1,
                color: '#555555',
                fillOpacity: 0.15
            };
        }
    }

    private onEachFeature(feature: any, layer: L.Layer): void {
        const { geoName, data } = this.getGeoInfo(feature);
        let tooltipContent = '<div class="noc-tooltip">';

        if (data) {
            const score = Number(data.scoreFinal ?? data.scoreTickets ?? 0);
            const level = this.getLevelFromScore(score);
            const levelClass = level.toLowerCase();

            tooltipContent += `<div class="tooltip-header">${data.zoneName}</div>`;
            tooltipContent += `<div class="tooltip-row"><span>Salud:</span> <span class="val-${levelClass}">${level} (${score}%)</span></div>`;
            tooltipContent += `<div class="tooltip-row"><span>Tickets:</span> <span>${data.openTickets}</span></div>`;
            tooltipContent += `<div class="tooltip-row"><span>Prioridad:</span> <span>${data.maxPriority || 'BAJA'}</span></div>`;
            tooltipContent += `<div class="tooltip-divider"></div>`;
            tooltipContent += `<div class="tooltip-footer">Latencia: ${data.latencyOverallMs.toFixed(2)} ms</div>`;
        } else {
            tooltipContent += `<div class="tooltip-header">${geoName || 'Desconocida'}</div>`;
            tooltipContent += `<div class="tooltip-error">Sin datos de telemetría</div>`;
        }
        tooltipContent += '</div>';

        layer.bindTooltip(tooltipContent, { sticky: true, className: 'noc-leaflet-tooltip' });

        layer.on({
            mouseover: (e: any) => {
                const lyr = e.target;
                lyr.setStyle({
                    weight: 4,
                    color: '#666',
                    fillOpacity: 0.9
                });
                lyr.bringToFront();
            },
            mouseout: (e: any) => {
                if (this.geojsonLayer) {
                    this.geojsonLayer.resetStyle(e.target);
                }
            }
        });
    }

    public toggleFullscreen(): void {
        const elem = document.querySelector('.network-map-container');
        if (!elem) return;

        if (!this.isFullscreen) {
            if (elem.requestFullscreen) {
                elem.requestFullscreen();
            }
        } else {
            if (document.exitFullscreen) {
                document.exitFullscreen();
            }
        }
        this.isFullscreen = !this.isFullscreen;
        setTimeout(() => this.map?.invalidateSize(), 300);
    }

    public fetchNetworkData(): void {
        this.networkService.refreshNow();
    }
}