import { Component, OnInit, OnDestroy, AfterViewInit } from '@angular/core';
import { CommonModule, DecimalPipe, DatePipe } from '@angular/common';
import { HttpClientModule } from '@angular/common/http';
import * as L from 'leaflet';
import 'leaflet.heat'; // We installed this earlier
import { NetworkService, NetworkMapData, HeatmapPoint } from '../../_services/network.service';
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
    private heatLayer: any;
    private heatmapMarkersLayer: L.LayerGroup | undefined;

    private networkData: NetworkMapData[] = [];
    private heatmapData: HeatmapPoint[] = [];
    private dataMap: Map<string, NetworkMapData> = new Map();

    private aliasMap: Map<string, string> = new Map([
        ['santo domingo de los tsachilas', 'santo domingo'],
        ['zona no delimitada', 'zonas no delimitadas'],
        ['canar', 'canar'],
        ['los rios', 'los rios'],
        ['galapagos', 'galapagos']
    ]);

    private dataSubscription: Subscription | undefined;
    private heatmapSubscription: Subscription | undefined;

    public overallLatency: number = 0;
    public dataSourceStatus: string = '';
    public lastUpdate: string = '';
    public isFullscreen: boolean = false;
    public isLoading: boolean = false;
    public errorLoading: boolean = false;
    public mapMode: 'CHOROPLETH' | 'HEATMAP' = 'CHOROPLETH';

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
        if (this.dataSubscription) this.dataSubscription.unsubscribe();
        if (this.heatmapSubscription) this.heatmapSubscription.unsubscribe();
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
                if (this.mapMode === 'CHOROPLETH') {
                    this.updateMapColors();
                }
            }
        });

        this.heatmapSubscription = this.networkService.heatmapData$.subscribe(points => {
            this.heatmapData = points;
            if (this.mapMode === 'HEATMAP') {
                this.renderHeatmap();
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

        L.tileLayer('https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png', {
            attribution: '&copy; <a href="https://carto.com/">CARTO</a>'
        }).addTo(this.map);

        this.heatmapMarkersLayer = L.layerGroup();

        this.map.on('zoomend', () => {
            if (this.mapMode === 'HEATMAP') {
                this.renderHeatmap();
            }
        });

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

        if (this.map && this.mapMode === 'CHOROPLETH') {
            this.geojsonLayer.addTo(this.map);
            this.fitLayerBounds();
        }
    }

    private fitLayerBounds(): void {
        if (this.geojsonLayer && this.map) {
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

    public toggleMapMode(): void {
        this.mapMode = this.mapMode === 'CHOROPLETH' ? 'HEATMAP' : 'CHOROPLETH';
        
        if (!this.map) return;

        if (this.mapMode === 'HEATMAP') {
            if (this.geojsonLayer) this.map.removeLayer(this.geojsonLayer);
            this.renderHeatmap();
        } else {
            if (this.heatLayer) this.map.removeLayer(this.heatLayer);
            if (this.heatmapMarkersLayer) this.map.removeLayer(this.heatmapMarkersLayer);
            if (this.geojsonLayer) {
                this.geojsonLayer.addTo(this.map);
                this.updateMapColors();
            }
        }
        
        // Force redraw and fix layout
        setTimeout(() => this.map?.invalidateSize(), 150);
    }

    private renderHeatmap(): void {
        if (!this.map) return;

        // Cleanup previous layers
        if (this.heatLayer) this.map.removeLayer(this.heatLayer);
        if (this.heatmapMarkersLayer) {
            this.heatmapMarkersLayer.clearLayers();
            this.heatmapMarkersLayer.addTo(this.map);
        }

        const currentZoom = this.map.getZoom();
        // Dynamic radius: larger for better visibility
        const dynamicRadius = Math.max(20, 35 + (currentZoom - 6) * 10);

        const heatPoints = this.heatmapData.map(p => [p.lat, p.lng, p.intensity]);

        // "Incendio" Gradient: Más intenso y brillante
        this.heatLayer = (L as any).heatLayer(heatPoints, {
            radius: dynamicRadius,
            blur: dynamicRadius * 0.4,
            maxZoom: 18,
            gradient: {
                0.2: '#feb24c', // Naranja suave
                0.4: '#fd8d3c', // Naranja medio
                0.6: '#f03b20', // Rojo
                0.8: '#bd0026', // Granate intenso
                1.0: '#800000'  // Sangre oscuro
            }
        }).addTo(this.map);

        // Add invisible markers for tooltips
        this.heatmapData.forEach(p => {
            const marker = L.circleMarker([p.lat, p.lng], {
                radius: dynamicRadius * 0.8,
                fillColor: 'transparent',
                fillOpacity: 0,
                color: 'transparent',
                opacity: 0,
                stroke: false
            });

            let tooltipContent = `
                <div class="noc-tooltip">
                    <div class="tooltip-header">${p.label || 'Incidencia'}</div>
                    <div class="tooltip-row"><span>Intensidad:</span> <span class="val-critical">${(p.intensity * 100).toFixed(0)}%</span></div>
                    <div class="tooltip-footer">Coordenadas: ${p.lat.toFixed(4)}, ${p.lng.toFixed(4)}</div>
                </div>
            `;
            marker.bindTooltip(tooltipContent, { sticky: true, className: 'noc-leaflet-tooltip' });
            this.heatmapMarkersLayer?.addLayer(marker);
        });
    }

    private updateMapColors(): void {
        if (this.geojsonLayer) {
            this.geojsonLayer.setStyle(this.getFeatureStyle.bind(this));
            this.geojsonLayer.eachLayer((layer: any) => {
                if (layer.feature) {
                    const { geoName, data } = this.getGeoInfo(layer.feature);
                    layer.setTooltipContent(this.createTooltipContent(geoName, data));
                }
            });
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

    private createTooltipContent(geoName: string, data: NetworkMapData | undefined): string {
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
        return tooltipContent;
    }

    private onEachFeature(feature: any, layer: L.Layer): void {
        const { geoName, data } = this.getGeoInfo(feature);
        layer.bindTooltip(this.createTooltipContent(geoName, data), { 
            sticky: true, 
            className: 'noc-leaflet-tooltip' 
        });

        layer.on({
            mouseover: (e: any) => {
                if (this.mapMode === 'HEATMAP') return;
                const lyr = e.target;
                lyr.setStyle({
                    weight: 4,
                    color: '#666',
                    fillOpacity: 0.9
                });
                lyr.bringToFront();
            },
            mouseout: (e: any) => {
                if (this.mapMode === 'HEATMAP') return;
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