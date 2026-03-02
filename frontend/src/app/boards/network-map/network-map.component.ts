import { Component, OnInit, OnDestroy, AfterViewInit } from '@angular/core';
import { CommonModule, DecimalPipe, DatePipe } from '@angular/common';
import { HttpClientModule } from '@angular/common/http';
import * as L from 'leaflet';
import { NetworkService, NetworkMapData } from '../../_services/network.service';
import { HttpClient } from '@angular/common/http';
import { Subscription, interval } from 'rxjs';

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
        // geoKey -> backendKey
        ['santo domingo de los tsachilas', 'santo domingo'],
        ['zona no delimitada', 'zonas no delimitadas'],
        ['canar', 'canar'],
        ['los rios', 'los rios'],
        ['galapagos', 'galapagos']
    ]);

    private unmatchedFeaturesCount: number = 0;
    private diagnosticsPrinted: boolean = false;
    private pollingSubscription: Subscription | undefined;

    public overallLatency: number = 0;
    public dataSourceStatus: string = '';
    public lastUpdate: string = '';

    // ---- NUEVO: caches para diagnóstico ----
    private lastGeoKeys: { original: string; normalized: string }[] = [];
    private lastBackendKeys: { original: string; normalized: string }[] = [];

    constructor(
        private networkService: NetworkService,
        private http: HttpClient
    ) { }

    ngOnInit(): void {
        this.fetchNetworkData();
        this.pollingSubscription = interval(60000).subscribe(() => {
            this.fetchNetworkData();
        });
    }

    ngAfterViewInit(): void {
        this.initMap();
        const rect = document.getElementById('networkMap')?.getBoundingClientRect();
        if (rect) {
            console.log(`networkMap rect after fix: w=${rect.width} h=${rect.height}`);
        }
    }

    ngOnDestroy(): void {
        if (this.pollingSubscription) {
            this.pollingSubscription.unsubscribe();
        }
    }

    private fetchNetworkData(): void {
        this.networkService.getNetworkMap('PROVINCIA').subscribe({
            next: (data) => {
                this.networkData = data;
                // ✅ DEBUG TEMPORAL: fuerza scores para probar WARNING/CRITICAL (BORRAR luego)
                for (const z of this.networkData) {
                    const key = this.normalizeName(z.zoneName);
                    if (key === 'azuay') z.scoreFinal = 75;   // WARNING (amarillo)
                    if (key === 'guayas') z.scoreFinal = 40;  // CRITICAL (rojo)
                }
                this.dataMap.clear();

                // ---- NUEVO: logs backend + tabla normalizada ----
                console.log('--- BACKEND RAW (NetworkMapData[]) ---');
                console.log(data);

                this.lastBackendKeys = (data || []).map(z => ({
                    original: z.zoneName,
                    normalized: this.normalizeName(z.zoneName)
                }));
                console.log('--- BACKEND NORMALIZED (zoneName) ---');
                console.table(this.lastBackendKeys);

                data.forEach(z => this.dataMap.set(this.normalizeName(z.zoneName), z));

                // Si ya se había cargado el mapa y aún no imprimimos diagnóstico,
                // imprimimos apenas tengamos backend + geojson
                if (this.geojsonLayer && !this.diagnosticsPrinted) {
                    this.printDiagnostics();
                }

                if (data.length > 0) {
                    this.overallLatency = data[0].latencyOverallMs;
                    this.dataSourceStatus = data[0].dataSource;
                    this.lastUpdate = data[0].lastSuccessfulCheckAt;
                }

                console.table(this.networkData.map(x => ({
                    zone: x.zoneName,
                    tickets: x.openTickets,
                    score: x.scoreFinal,
                    backendLevel: x.level
                })));

                this.updateMapColors();
            },
            error: (err) => console.error('Error fetching network map data', err)
        });
    }

    private initMap(): void {
        this.map = L.map('networkMap', {
            center: [-1.8312, -78.1834],
            zoom: 6
        });

        L.tileLayer('https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png', {
            attribution: '&copy; <a href="https://carto.com/">CARTO</a>'
        }).addTo(this.map);

        this.loadGeoJSON();
    }

    private loadGeoJSON(): void {
        if (this.geojsonLayer && this.map) {
            this.map.removeLayer(this.geojsonLayer);
        }

        this.unmatchedFeaturesCount = 0;

        this.http.get('assets/ecuador.geojson').subscribe({
            next: (geojsonData: any) => {
                // Logs de diagnóstico obligatorios (los tuyos)
                console.log('geojson.type', geojsonData?.type);
                console.log('features', geojsonData?.features?.length);
                console.log('first geometry type', geojsonData?.features?.[0]?.geometry?.type);
                console.log('first coord sample', geojsonData?.features?.[0]?.geometry?.coordinates?.[0]?.[0]);

                // ---- NUEVO: tabla de nombres del geojson (normalizados) ----
                this.lastGeoKeys = (geojsonData?.features || []).map((f: any) => {
                    const props = f?.properties || {};
                    const geoName =
                        props.dpa_despro ||
                        props.DPA_DESPRO ||
                        props.nombre ||
                        props.NOMBRE ||
                        props.name ||
                        props.NAME_1 ||
                        props.NAME ||
                        props.provincia ||
                        props.PROVINCIA ||
                        '';
                    return {
                        original: geoName,
                        normalized: this.normalizeName(geoName)
                    };
                });

                console.log('--- GEOJSON NAMES (normalized) ---');
                console.table(this.lastGeoKeys);

                this.geojsonLayer = L.geoJSON(geojsonData as any, {
                    style: this.getFeatureStyle.bind(this),
                    onEachFeature: this.onEachFeature.bind(this)
                });

                if (this.map) {
                    this.geojsonLayer.addTo(this.map);

                    const bounds = this.geojsonLayer.getBounds();
                    console.log('bounds valid', bounds.isValid(), bounds);

                    if (bounds.isValid()) {
                        this.map.fitBounds(bounds, { padding: [20, 20] });
                    }

                    setTimeout(() => {
                        this.map?.invalidateSize();
                    }, 200);
                }

                // si tenemos backend cargado también, imprime diagnóstico completo
                if (this.networkData?.length && !this.diagnosticsPrinted) {
                    this.printDiagnostics();
                }

                if (this.unmatchedFeaturesCount > 0) {
                    console.log(`[Network Map] ${this.unmatchedFeaturesCount} provinces without active tickets loaded with default styling.`);
                }
            },
            error: (err) => console.error('Error cargando assets/ecuador.geojson. Asegúrate de que exista en src/assets/', err)
        });
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

    // ---- NUEVO: helper para aplicar alias (geoKey -> backendKey) ----
    private resolveBackendKeyFromGeoKey(geoKey: string): string {
        // Primero intentamos match directo (por si el backend envía el nombre largo/completo)
        if (this.dataMap.has(geoKey)) {
            return geoKey;
        }
        const alias = this.aliasMap.get(geoKey);
        return alias ? alias : geoKey;
    }

    private printDiagnostics(): void {
        if (!this.geojsonLayer) return;
        this.diagnosticsPrinted = true;

        // construir set real desde layers (más confiable que features crudos)
        const geoKeys = new Set<string>();
        const geoNames = new Map<string, string>();

        this.geojsonLayer.eachLayer((layer: any) => {
            const props = layer.feature?.properties || {};
            const geoName =
                props.dpa_despro || props.DPA_DESPRO ||
                props.nombre || props.NOMBRE ||
                props.name || props.NAME_1 || props.NAME ||
                props.provincia || props.PROVINCIA || '';

            const geoKey = this.normalizeName(geoName);
            if (geoKey) {
                geoKeys.add(geoKey);
                geoNames.set(geoKey, geoName);
            }
        });

        const backendKeys = Array.from(this.dataMap.keys());

        console.log('--- DIAGNOSTICO MATCHING GEOJSON VS BACKEND ---');
        console.log('GeoJSON keys (normalized):', Array.from(geoKeys));
        console.log('Backend keys (normalized):', backendKeys);

        // GeoJSON que no aparece ni directo ni por alias
        const inGeoNotBackend = Array.from(geoKeys).filter(gk => {
            const mapped = this.resolveBackendKeyFromGeoKey(gk);
            return !this.dataMap.has(mapped);
        });

        // Backend que no existe en geojson ni como destino de alias
        const aliasTargets = new Set(Array.from(this.aliasMap.values()));
        const inBackendNotGeo = backendKeys.filter(bk => {
            const isDirect = geoKeys.has(bk);
            const isAliasTarget = aliasTargets.has(bk);
            return !isDirect && !isAliasTarget;
        });

        console.log('En GeoJSON pero NO en Backend:', inGeoNotBackend.map(k => ({
            geoName: geoNames.get(k),
            geoKey: k,
            aliasTarget: this.aliasMap.get(k) || null
        })));

        console.log('En Backend pero NO en GeoJSON:', inBackendNotGeo);

        console.log(`Matched provinces: ${geoKeys.size - inGeoNotBackend.length}/${geoKeys.size}`);
        console.log('----------------------------------------------');

        // ---- NUEVO: comparaciones rápidas usando las tablas cacheadas ----
        if (this.lastGeoKeys.length && this.lastBackendKeys.length) {
            const geoSet = new Set(this.lastGeoKeys.map(x => x.normalized));
            const backSet = new Set(this.lastBackendKeys.map(x => x.normalized));

            const onlyInGeo = [...geoSet].filter(k => !backSet.has(this.resolveBackendKeyFromGeoKey(k)));
            const onlyInBackend = [...backSet].filter(k => !geoSet.has(k));

            console.log('--- SOLO EN GEOJSON (no existe en backend ni alias) ---', onlyInGeo);
            console.log('--- SOLO EN BACKEND (no existe en geojson) ---', onlyInBackend);
        }
    }

    private getGeoInfo(feature: any): { geoName: string, geoKey: string, backendKey: string, data: NetworkMapData | undefined } {
        const props: any = feature?.properties || {};
        const geoName =
            props.dpa_despro || props.DPA_DESPRO ||
            props.nombre || props.NOMBRE ||
            props.name || props.NAME_1 || props.NAME ||
            props.provincia || props.PROVINCIA || '';

        const geoKey = this.normalizeName(geoName);
        const backendKey = this.resolveBackendKeyFromGeoKey(geoKey);

        let data = this.dataMap.get(backendKey);

        return { geoName, geoKey, backendKey, data };
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
        const { geoName, geoKey, backendKey, data } = this.getGeoInfo(feature);
        let tooltipContent = '';

        if (data) {
            const score = Number(data.scoreFinal ?? data.scoreTickets ?? 0);
            const level = this.getLevelFromScore(score);

            tooltipContent += `<strong>Provincia:</strong> ${data.zoneName}<br/>`;
            tooltipContent += `<strong>Salud General:</strong> ${level} (${score}/100)<br/>`;
            tooltipContent += `<strong>Tickets Abiertos:</strong> ${data.openTickets}<br/>`;
            tooltipContent += `<strong>Prioridad Máxima:</strong> ${data.maxPriority}<br/>`;
            tooltipContent += `<strong>Latencia Global EC:</strong> ${data.latencyOverallMs.toFixed(2)} ms<br/>`;
        } else {
            tooltipContent += `<strong>Provincia:</strong> ${geoName || 'Desconocida'}<br/>`;
            tooltipContent += `Sin datos del backend`;
            this.unmatchedFeaturesCount++;
        }

        layer.bindTooltip(tooltipContent);

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

        // ---- MEJORADO: click imprime TODO lo necesario para debug ----
        layer.on('click', () => {
            console.log('Clicked on province DEBUG =>', {
                geoName,
                geoKey,
                backendKey,
                aliasUsed: this.aliasMap.get(geoKey) || null,
                hasBackendKey: this.dataMap.has(backendKey),
                data: data || null
            });
        });
    }
}