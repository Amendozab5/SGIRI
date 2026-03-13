package com.apweb.backend.service;

import com.apweb.backend.model.VwCsatDetalle;
import com.apweb.backend.model.VwResumenTickets;
import com.apweb.backend.model.VwSlaTecnico;
import org.apache.poi.ss.usermodel.*;
import org.apache.poi.xssf.usermodel.XSSFCellStyle;
import org.apache.poi.xssf.usermodel.XSSFColor;
import org.apache.poi.xssf.usermodel.XSSFFont;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.springframework.stereotype.Service;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.time.format.DateTimeFormatter;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
public class ExcelReporteService {

    private final DateTimeFormatter dateTimeFormatter = DateTimeFormatter.ofPattern("dd-MMM-yyyy HH:mm");

    // Paleta de Colores Refinada (Excel Standard)
    private static final byte[] RGB_ZEBRA = new byte[]{(byte) 248, (byte) 250, (byte) 252}; // #F8FAFC
    private static final byte[] RGB_GOLD = new byte[]{(byte) 212, (byte) 175, (byte) 55}; // Dorado para estrellas
    
    // Colores de Estados (Backgrounds)
    private static final byte[] RGB_ASIGNADO_BG = new byte[]{(byte) 217, (byte) 225, (byte) 242}; // #D9E1F2
    private static final byte[] RGB_RESUELTO_BG = new byte[]{(byte) 226, (byte) 239, (byte) 218}; // #E2EFDA
    private static final byte[] RGB_CERRADO_BG = new byte[]{(byte) 242, (byte) 242, (byte) 242}; // #F2F2F2
    private static final byte[] RGB_VISITA_BG = new byte[]{(byte) 255, (byte) 242, (byte) 204};   // #FFF2CC
    
    // Colores de Prioridades
    private static final byte[] RGB_CRITICA_BG = new byte[]{(byte) 255, (byte) 199, (byte) 206}; // #FFC7CE
    private static final byte[] RGB_CRITICA_TXT = new byte[]{(byte) 156, (byte) 0, (byte) 6};    // #9C0006
    private static final byte[] RGB_BAJA_TXT = new byte[]{(byte) 0, (byte) 128, (byte) 0};       // #008000

    public ByteArrayInputStream generateTicketsExcel(List<VwResumenTickets> data) throws IOException {
        try (Workbook workbook = new XSSFWorkbook(); ByteArrayOutputStream out = new ByteArrayOutputStream()) {
            Sheet sheet = workbook.createSheet("Tickets");

            // --- Cache de Estilos ---
            CellStyle headerStyle = createHeaderStyle(workbook);
            CellStyle zebraStyle = createZebraStyle(workbook);
            Map<String, CellStyle> statusStyles = createStatusStyles(workbook);
            Map<String, CellStyle> priorityStyles = createPriorityStyles(workbook);
            CellStyle starStyle = createStarStyle(workbook);

            // --- Encabezados ---
            String[] headers = {"ID", "Asunto", "Fecha Creación", "Fecha Cierre", "Estado", "Prioridad", "Tiempo Resolución", "Calificación", "Categoría"};
            Row headerRow = sheet.createRow(0);
            for (int i = 0; i < headers.length; i++) {
                Cell cell = headerRow.createCell(i);
                cell.setCellValue(headers[i]);
                cell.setCellStyle(headerStyle);
            }

            // --- Datos ---
            int rowIdx = 1;
            for (VwResumenTickets t : data) {
                Row row = sheet.createRow(rowIdx++);
                boolean isZebra = (rowIdx % 2 == 0);
                CellStyle baseStyle = isZebra ? zebraStyle : null;

                createStyledCell(row, 0, "#" + t.getIdTicket(), baseStyle != null ? baseStyle : createSimpleBorderedStyle(workbook));
                createStyledCell(row, 1, t.getAsunto(), baseStyle != null ? baseStyle : createSimpleBorderedStyle(workbook));
                createStyledCell(row, 2, t.getFechaCreacion() != null ? t.getFechaCreacion().format(dateTimeFormatter) : "-", baseStyle != null ? baseStyle : createSimpleBorderedStyle(workbook));
                createStyledCell(row, 3, t.getFechaCierre() != null ? t.getFechaCierre().format(dateTimeFormatter) : "-", baseStyle != null ? baseStyle : createSimpleBorderedStyle(workbook));

                // Estado con color
                Cell estadoCell = row.createCell(4);
                estadoCell.setCellValue(t.getEstado());
                estadoCell.setCellStyle(statusStyles.getOrDefault(t.getEstadoCodigo(), baseStyle));

                // Prioridad con color
                Cell prioCell = row.createCell(5);
                prioCell.setCellValue(t.getPrioridad());
                prioCell.setCellStyle(priorityStyles.getOrDefault(t.getPrioridad() != null ? t.getPrioridad().toUpperCase() : "", baseStyle));

                createStyledCell(row, 6, formatTiempoResolucion(t.getTiempoResolucion()), baseStyle != null ? baseStyle : createSimpleBorderedStyle(workbook));
                
                // Calificación (Stars en dorado)
                Cell starCell = row.createCell(7);
                starCell.setCellValue(t.getCalificacionSatisfaccion() != null ? t.getCalificacionSatisfaccion() + "★" : "Pendiente");
                starCell.setCellStyle(t.getCalificacionSatisfaccion() != null ? starStyle : baseStyle);

                createStyledCell(row, 8, t.getCategoria(), baseStyle != null ? baseStyle : createSimpleBorderedStyle(workbook));
            }

            finalizeSheet(sheet, headers.length);
            workbook.write(out);
            return new ByteArrayInputStream(out.toByteArray());
        }
    }

    public ByteArrayInputStream generateSlaExcel(List<VwSlaTecnico> data) throws IOException {
        try (Workbook workbook = new XSSFWorkbook(); ByteArrayOutputStream out = new ByteArrayOutputStream()) {
            Sheet sheet = workbook.createSheet("SLA Técnico");
            CellStyle headerStyle = createHeaderStyle(workbook);
            CellStyle zebraStyle = createZebraStyle(workbook);

            String[] headers = {"Técnico", "Total Tickets", "Tickets Resueltos", "SLA Cumplido", "T. Prom. Resolución"};
            Row headerRow = sheet.createRow(0);
            for (int i = 0; i < headers.length; i++) {
                Cell cell = headerRow.createCell(i);
                cell.setCellValue(headers[i]);
                cell.setCellStyle(headerStyle);
            }

            int rowIdx = 1;
            for (VwSlaTecnico s : data) {
                Row row = sheet.createRow(rowIdx++);
                CellStyle style = (rowIdx % 2 == 0) ? zebraStyle : null;
                
                createStyledCell(row, 0, s.getTecnicoNombre(), style != null ? style : createSimpleBorderedStyle(workbook));
                createStyledCell(row, 1, String.valueOf(s.getTotalTickets()), style != null ? style : createSimpleBorderedStyle(workbook));
                createStyledCell(row, 2, String.valueOf(s.getTicketsResueltos()), style != null ? style : createSimpleBorderedStyle(workbook));
                createStyledCell(row, 3, String.valueOf(s.getSlaCumplido()), style != null ? style : createSimpleBorderedStyle(workbook));
                createStyledCell(row, 4, s.getAvgResolucionHoras() + "h", style != null ? style : createSimpleBorderedStyle(workbook));
            }

            finalizeSheet(sheet, headers.length);
            workbook.write(out);
            return new ByteArrayInputStream(out.toByteArray());
        }
    }

    public ByteArrayInputStream generateCsatExcel(List<VwCsatDetalle> data) throws IOException {
        try (Workbook workbook = new XSSFWorkbook(); ByteArrayOutputStream out = new ByteArrayOutputStream()) {
            Sheet sheet = workbook.createSheet("Satisfacción Cliente");
            CellStyle headerStyle = createHeaderStyle(workbook);
            CellStyle zebraStyle = createZebraStyle(workbook);
            CellStyle starStyle = createStarStyle(workbook);

            String[] headers = {"Cliente", "Asunto", "ID Ticket", "Calificación", "Comentario", "Fecha Cierre", "Categoría"};
            Row headerRow = sheet.createRow(0);
            for (int i = 0; i < headers.length; i++) {
                Cell cell = headerRow.createCell(i);
                cell.setCellValue(headers[i]);
                cell.setCellStyle(headerStyle);
            }

            int rowIdx = 1;
            for (VwCsatDetalle d : data) {
                Row row = sheet.createRow(rowIdx++);
                CellStyle style = (rowIdx % 2 == 0) ? zebraStyle : null;

                createStyledCell(row, 0, d.getClienteNombre(), style != null ? style : createSimpleBorderedStyle(workbook));
                createStyledCell(row, 1, d.getAsunto(), style != null ? style : createSimpleBorderedStyle(workbook));
                createStyledCell(row, 2, "#" + d.getIdTicket(), style != null ? style : createSimpleBorderedStyle(workbook));
                
                Cell starCell = row.createCell(3);
                starCell.setCellValue(d.getCalificacionSatisfaccion() + "★");
                starCell.setCellStyle(starStyle);

                createStyledCell(row, 4, d.getComentarioCalificacion() != null ? d.getComentarioCalificacion() : "-", style != null ? style : createSimpleBorderedStyle(workbook));
                createStyledCell(row, 5, d.getFechaCierre() != null ? d.getFechaCierre().format(dateTimeFormatter) : "-", style != null ? style : createSimpleBorderedStyle(workbook));
                createStyledCell(row, 6, d.getCategoria(), style != null ? style : createSimpleBorderedStyle(workbook));
            }

            finalizeSheet(sheet, headers.length);
            workbook.write(out);
            return new ByteArrayInputStream(out.toByteArray());
        }
    }

    private Cell createStyledCell(Row row, int column, String value, CellStyle style) {
        Cell cell = row.createCell(column);
        cell.setCellValue(value != null ? value : "");
        if (style != null) cell.setCellStyle(style);
        return cell;
    }

    private CellStyle createHeaderStyle(Workbook workbook) {
        CellStyle style = workbook.createCellStyle();
        XSSFColor color = new XSSFColor(new byte[]{(byte)0, (byte)0, (byte)0}, null); // Black based on screenshot
        ((XSSFCellStyle) style).setFillForegroundColor(color);
        style.setFillPattern(FillPatternType.SOLID_FOREGROUND);
        Font font = workbook.createFont();
        font.setBold(true);
        font.setColor(IndexedColors.WHITE.getIndex());
        style.setFont(font);
        style.setAlignment(HorizontalAlignment.CENTER);
        
        style.setBorderTop(BorderStyle.THIN);
        style.setBorderBottom(BorderStyle.THIN);
        style.setBorderLeft(BorderStyle.THIN);
        style.setBorderRight(BorderStyle.THIN);
        style.setTopBorderColor(IndexedColors.BLACK.getIndex());
        style.setBottomBorderColor(IndexedColors.BLACK.getIndex());
        style.setLeftBorderColor(IndexedColors.BLACK.getIndex());
        style.setRightBorderColor(IndexedColors.BLACK.getIndex());
        return style;
    }

    private CellStyle createZebraStyle(Workbook workbook) {
        CellStyle style = workbook.createCellStyle();
        XSSFColor color = new XSSFColor(RGB_ZEBRA, null);
        ((XSSFCellStyle) style).setFillForegroundColor(color);
        style.setFillPattern(FillPatternType.SOLID_FOREGROUND);
        
        style.setBorderTop(BorderStyle.THIN);
        style.setBorderBottom(BorderStyle.THIN);
        style.setBorderLeft(BorderStyle.THIN);
        style.setBorderRight(BorderStyle.THIN);
        return style;
    }

    private CellStyle createSimpleBorderedStyle(Workbook workbook) {
        CellStyle style = workbook.createCellStyle();
        style.setBorderTop(BorderStyle.THIN);
        style.setBorderBottom(BorderStyle.THIN);
        style.setBorderLeft(BorderStyle.THIN);
        style.setBorderRight(BorderStyle.THIN);
        return style;
    }

    private CellStyle createStarStyle(Workbook workbook) {
        CellStyle style = workbook.createCellStyle();
        Font font = workbook.createFont();
        font.setBold(true);
        XSSFColor gold = new XSSFColor(RGB_GOLD, null);
        ((XSSFFont) font).setColor(gold);
        style.setFont(font);
        style.setAlignment(HorizontalAlignment.CENTER);
        
        style.setBorderTop(BorderStyle.THIN);
        style.setBorderBottom(BorderStyle.THIN);
        style.setBorderLeft(BorderStyle.THIN);
        style.setBorderRight(BorderStyle.THIN);
        return style;
    }

    private Map<String, CellStyle> createStatusStyles(Workbook workbook) {
        Map<String, CellStyle> styles = new HashMap<>();
        
        // ASIGNADO: Celeste fondo, Texto Negro
        styles.put("OPEN", createBaseStatusStyle(workbook, RGB_ASIGNADO_BG, IndexedColors.BLACK.getIndex(), false));
        styles.put("ASIGNADO", createBaseStatusStyle(workbook, RGB_ASIGNADO_BG, IndexedColors.BLACK.getIndex(), false));
        
        // RESUELTO: Verde suave fondo, Texto Negro
        styles.put("RESUELTO", createBaseStatusStyle(workbook, RGB_RESUELTO_BG, IndexedColors.BLACK.getIndex(), false));
        
        // CERRADO: Gris suave fondo, Texto Negro
        styles.put("CLOSED", createBaseStatusStyle(workbook, RGB_CERRADO_BG, IndexedColors.BLACK.getIndex(), false));
        styles.put("CERRADO", createBaseStatusStyle(workbook, RGB_CERRADO_BG, IndexedColors.BLACK.getIndex(), false));
        
        // REQUIERE_VISITA: Amarillo suave fondo, Texto Negro
        styles.put("EN_PROCESO", createBaseStatusStyle(workbook, RGB_VISITA_BG, IndexedColors.BLACK.getIndex(), false));
        styles.put("REQUIERE_VISITA", createBaseStatusStyle(workbook, RGB_VISITA_BG, IndexedColors.BLACK.getIndex(), false));
        
        return styles;
    }

    private Map<String, CellStyle> createPriorityStyles(Workbook workbook) {
        Map<String, CellStyle> styles = new HashMap<>();
        
        // CRÍTICA: Rojo suave fondo, Texto Rojo Oscuro
        CellStyle style = createBaseStatusStyle(workbook, RGB_CRITICA_BG, RGB_CRITICA_TXT, true);
        styles.put("CRITICA", style);
        styles.put("CRÍTICA", style);
        
        // ALTA / MEDIA: Amarillo suave fondo, Texto Negro (Media en Negrita)
        styles.put("ALTA", createBaseStatusStyle(workbook, RGB_VISITA_BG, IndexedColors.BLACK.getIndex(), false));
        styles.put("MEDIA", createBaseStatusStyle(workbook, RGB_VISITA_BG, IndexedColors.BLACK.getIndex(), true));
        
        // BAJA: Verde suave fondo, Texto Verde Oscuro
        styles.put("BAJA", createBaseStatusStyle(workbook, RGB_RESUELTO_BG, RGB_BAJA_TXT, false));

        return styles;
    }

    private CellStyle createBaseStatusStyle(Workbook workbook, byte[] bgColor, short textColorIndex, boolean bold) {
        CellStyle style = workbook.createCellStyle();
        XSSFColor color = new XSSFColor(bgColor, null);
        ((XSSFCellStyle) style).setFillForegroundColor(color);
        style.setFillPattern(FillPatternType.SOLID_FOREGROUND);
        style.setAlignment(HorizontalAlignment.CENTER);
        
        style.setBorderTop(BorderStyle.THIN);
        style.setBorderBottom(BorderStyle.THIN);
        style.setBorderLeft(BorderStyle.THIN);
        style.setBorderRight(BorderStyle.THIN);
        
        Font font = workbook.createFont();
        font.setBold(bold);
        font.setColor(textColorIndex);
        style.setFont(font);
        return style;
    }

    private CellStyle createBaseStatusStyle(Workbook workbook, byte[] bgColor, byte[] textColor, boolean bold) {
        CellStyle style = workbook.createCellStyle();
        XSSFColor color = new XSSFColor(bgColor, null);
        ((XSSFCellStyle) style).setFillForegroundColor(color);
        style.setFillPattern(FillPatternType.SOLID_FOREGROUND);
        style.setAlignment(HorizontalAlignment.CENTER);
        
        style.setBorderTop(BorderStyle.THIN);
        style.setBorderBottom(BorderStyle.THIN);
        style.setBorderLeft(BorderStyle.THIN);
        style.setBorderRight(BorderStyle.THIN);
        
        XSSFFont font = (XSSFFont) workbook.createFont();
        font.setBold(bold);
        font.setColor(new XSSFColor(textColor, null));
        style.setFont(font);
        return style;
    }

    private void finalizeSheet(Sheet sheet, int columnCount) {
        sheet.createFreezePane(0, 1);
        for (int i = 0; i < columnCount; i++) {
            sheet.autoSizeColumn(i);
        }
    }

    private String formatTiempoResolucion(String raw) {
        if (raw == null || raw.isEmpty()) return "-";
        try {
            String result = raw.replace("days", "días").replace("day", "día");
            if (result.contains(".")) result = result.substring(0, result.lastIndexOf("."));
            if (result.contains(":")) {
                String[] parts = result.split(" ");
                String timePart = parts[parts.length - 1];
                String[] timeParts = timePart.split(":");
                String cleanTime = Integer.parseInt(timeParts[0]) + "h " + Integer.parseInt(timeParts[1]) + "m";
                if (parts.length > 1) return parts[0] + " " + parts[1] + " " + cleanTime;
                else return cleanTime;
            }
            return result;
        } catch (Exception e) {
            return raw;
        }
    }
}
