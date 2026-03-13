package com.apweb.backend.service;

import com.apweb.backend.model.*;
import com.lowagie.text.*;
import com.lowagie.text.Font;
import com.lowagie.text.Rectangle;
import com.lowagie.text.pdf.*;
import org.springframework.stereotype.Service;

import java.awt.Color;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;

@Service
public class PdfReporteService {

    // Paleta de Colores Armónica (Coherente con Excel y UI)
    private static final Color DARK_BG = new Color(30, 64, 175); // Azul estándar SGIRI (basado en badges primarios)
    private static final Color WHITE = Color.WHITE;
    private static final Color ZEBRA_ROW = new Color(248, 250, 252); // #F8FAFC
    private static final Color GOLD = new Color(212, 175, 55);
    
    // Colores para Badges (Refinado - Standard Excel/SGIRI)
    private static final Color BG_ASIGNADO = new Color(217, 225, 242); // #D9E1F2
    private static final Color BG_RESUELTO = new Color(226, 239, 218); // #E2EFDA
    private static final Color BG_CERRADO  = new Color(242, 242, 242); // #F2F2F2
    private static final Color BG_VISITA   = new Color(255, 242, 204); // #FFF2CC
    
    private static final Color BG_CRITICAL = new Color(255, 199, 206); // #FFC7CE
    private static final Color TEXT_CRITICAL = new Color(156, 0, 6);   // #9C0006
    private static final Color TEXT_BAJA     = new Color(0, 128, 0);   // #008000

    private final DateTimeFormatter dateTimeFormatter = DateTimeFormatter.ofPattern("dd-MMM-yyyy HH:mm");

    // Clase para manejar Pie de Página y Numeración
    class PageFooter extends PdfPageEventHelper {
        public void onEndPage(PdfWriter writer, Document document) {
            PdfPTable footer = new PdfPTable(2);
            try {
                footer.setWidths(new int[]{5, 2});
                footer.setTotalWidth(527);
                footer.setLockedWidth(true);
                footer.getDefaultCell().setBorder(Rectangle.NO_BORDER);
                
                Font footerFont = FontFactory.getFont(FontFactory.HELVETICA_OBLIQUE, 8, Color.GRAY);
                footer.addCell(new Phrase("SGIRI - Sistema de Gestión de Incidencias Operativas", footerFont));
                
                PdfPCell pageCell = new PdfPCell(new Phrase(String.format("Página %d", writer.getPageNumber()), footerFont));
                pageCell.setHorizontalAlignment(Element.ALIGN_RIGHT);
                pageCell.setBorder(Rectangle.NO_BORDER);
                footer.addCell(pageCell);
                
                footer.writeSelectedRows(0, -1, 34, 30, writer.getDirectContent());
            } catch (Exception e) {}
        }
    }

    private void addHeader(Document document, String title, int registerCount) throws DocumentException {
        // Banner con diseño Premium
        PdfPTable headerTable = new PdfPTable(1);
        headerTable.setWidthPercentage(100);

        PdfPCell banner = new PdfPCell();
        banner.setBackgroundColor(DARK_BG);
        banner.setBorder(Rectangle.NO_BORDER);
        banner.setPadding(20);

        Font titleFont = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 20, WHITE);
        Font subTitleFont = FontFactory.getFont(FontFactory.HELVETICA, 10, new Color(200, 200, 200));

        banner.addElement(new Phrase("SGIRI - REPORTES DEL SISTEMA", subTitleFont));
        banner.addElement(new Phrase(title.toUpperCase(), titleFont));
        headerTable.addCell(banner);
        document.add(headerTable);

        // Metadata Bar
        PdfPTable metaTable = new PdfPTable(2);
        metaTable.setWidthPercentage(100);
        metaTable.setSpacingBefore(10);
        metaTable.setSpacingAfter(15);

        Font metaFont = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 9, Color.DARK_GRAY);
        String fecha = LocalDateTime.now().format(dateTimeFormatter);

        PdfPCell leftCell = new PdfPCell(new Phrase("GENERADO: " + fecha, metaFont));
        leftCell.setBorder(Rectangle.BOTTOM);
        leftCell.setBorderColor(new Color(230, 230, 230));
        leftCell.setPaddingBottom(5);

        PdfPCell rightCell = new PdfPCell(new Phrase("TOTAL REGISTROS: " + registerCount, metaFont));
        rightCell.setBorder(Rectangle.BOTTOM);
        rightCell.setBorderColor(new Color(230, 230, 230));
        rightCell.setPaddingBottom(5);
        rightCell.setHorizontalAlignment(Element.ALIGN_RIGHT);

        metaTable.addCell(leftCell);
        metaTable.addCell(rightCell);
        document.add(metaTable);
    }

    private PdfPCell getHeaderCell(String text) {
        Font font = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 10, WHITE);
        PdfPCell cell = new PdfPCell(new Phrase(text.toUpperCase(), font));
        cell.setBackgroundColor(DARK_BG);
        cell.setPadding(10);
        cell.setHorizontalAlignment(Element.ALIGN_CENTER);
        cell.setBorder(Rectangle.BOX);
        cell.setBorderWidth(1);
        cell.setBorderColor(Color.BLACK);
        return cell;
    }

    private PdfPCell getDataCell(String text, boolean zebra) {
        Font font = FontFactory.getFont(FontFactory.HELVETICA, 9, Color.BLACK);
        PdfPCell cell = new PdfPCell(new Phrase(text != null ? text : "-", font));
        if (zebra) cell.setBackgroundColor(ZEBRA_ROW);
        cell.setPadding(8);
        cell.setBorder(Rectangle.BOX);
        cell.setBorderWidth(0.5f);
        cell.setBorderColor(Color.BLACK);
        return cell;
    }

    private PdfPCell getBadgeCell(String text, String code, boolean zebra) {
        Color bgColor = Color.WHITE;
        Color textColor = Color.BLACK;
        boolean isBold = true;
        
        if (code != null) {
            switch (code.toUpperCase()) {
                case "OPEN":
                case "ASIGNADO": 
                    bgColor = BG_ASIGNADO; textColor = Color.BLACK; isBold = false; break;
                case "RESUELTO": 
                    bgColor = BG_RESUELTO; textColor = Color.BLACK; isBold = false; break;
                case "EN_PROCESO":
                case "REQUIERE_VISITA":
                    bgColor = BG_VISITA; textColor = Color.BLACK; isBold = false; break;
                case "CERRADO":
                case "CLOSED":
                    bgColor = BG_CERRADO; textColor = Color.BLACK; isBold = false; break;
                
                // Prioridades
                case "CRITICA":
                case "CRÍTICA": 
                    bgColor = BG_CRITICAL; textColor = TEXT_CRITICAL; isBold = true; break;
                case "ALTA": 
                    bgColor = BG_VISITA; textColor = Color.BLACK; isBold = false; break;
                case "MEDIA": 
                    bgColor = BG_VISITA; textColor = Color.BLACK; isBold = true; break;
                case "BAJA": 
                    bgColor = BG_RESUELTO; textColor = TEXT_BAJA; isBold = false; break;
            }
        }

        Font font = FontFactory.getFont(FontFactory.HELVETICA, 8, isBold ? Font.BOLD : Font.NORMAL, textColor);
        PdfPCell cell = new PdfPCell(new Phrase(text.toUpperCase(), font));
        cell.setBackgroundColor(bgColor);
        cell.setPadding(8);
        cell.setHorizontalAlignment(Element.ALIGN_CENTER);
        cell.setVerticalAlignment(Element.ALIGN_MIDDLE);
        cell.setBorder(Rectangle.BOX);
        cell.setBorderWidth(0.5f);
        cell.setBorderColor(Color.BLACK);
        return cell;
    }

    public ByteArrayInputStream generateTicketsReport(List<VwResumenTickets> data) {
        Document document = new Document(PageSize.A4.rotate());
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        try {
            PdfWriter writer = PdfWriter.getInstance(document, out);
            writer.setPageEvent(new PageFooter());
            document.open();
            addHeader(document, "Reporte Operativo de Gestión de Tickets", data.size());

            PdfPTable table = new PdfPTable(7);
            table.setWidthPercentage(100);
            table.setWidths(new float[] { 1, 3, 2, 1.5f, 1.5f, 1, 1.5f });

            String[] headers = { "ID", "Asunto", "Categoría", "Estado", "Prioridad", "CSAT", "T. Res" };
            for (String h : headers) table.addCell(getHeaderCell(h));

            int i = 0;
            for (VwResumenTickets t : data) {
                boolean z = (i % 2 == 1);
                table.addCell(getDataCell("#" + t.getIdTicket(), z));
                table.addCell(getDataCell(t.getAsunto(), z));
                table.addCell(getDataCell(t.getCategoria(), z));
                table.addCell(getBadgeCell(t.getEstado(), t.getEstadoCodigo(), z));
                table.addCell(getBadgeCell(t.getPrioridad(), t.getPrioridad(), z));
                
                // CSAT Stars
                Font starFont = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 10, GOLD);
                String stars = t.getCalificacionSatisfaccion() != null ? t.getCalificacionSatisfaccion() + "★" : "-";
                PdfPCell starCell = new PdfPCell(new Phrase(stars, starFont));
                if (z) starCell.setBackgroundColor(ZEBRA_ROW);
                starCell.setPadding(8);
                starCell.setHorizontalAlignment(Element.ALIGN_CENTER);
                starCell.setBorder(Rectangle.BOX);
                starCell.setBorderWidth(0.5f);
                starCell.setBorderColor(Color.BLACK);
                table.addCell(starCell);

                table.addCell(getDataCell(formatTiempoResolucion(t.getTiempoResolucion()), z));
                i++;
            }
            document.add(table);
            document.close();
        } catch (Exception e) { e.printStackTrace(); }
        return new ByteArrayInputStream(out.toByteArray());
    }

    public ByteArrayInputStream generateSlaReport(List<VwSlaTecnico> data) {
        Document document = new Document(PageSize.A4);
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        try {
            PdfWriter writer = PdfWriter.getInstance(document, out);
            writer.setPageEvent(new PageFooter());
            document.open();
            addHeader(document, "Reporte de Cumplimiento de SLA por Técnico", data.size());

            PdfPTable table = new PdfPTable(5);
            table.setWidthPercentage(100);
            String[] headers = { "Técnico", "Total", "Resueltos", "SLA Cumplido", "Prom. Res." };
            for (String h : headers) table.addCell(getHeaderCell(h));

            int i = 0;
            for (VwSlaTecnico s : data) {
                boolean z = (i % 2 == 1);
                table.addCell(getDataCell(s.getTecnicoNombre(), z));
                table.addCell(getDataCell(String.valueOf(s.getTotalTickets()), z));
                table.addCell(getDataCell(String.valueOf(s.getTicketsResueltos()), z));
                table.addCell(getDataCell(String.valueOf(s.getSlaCumplido()), z));
                table.addCell(getDataCell(s.getAvgResolucionHoras() + "h", z));
                i++;
            }
            document.add(table);
            document.close();
        } catch (Exception e) { e.printStackTrace(); }
        return new ByteArrayInputStream(out.toByteArray());
    }

    public ByteArrayInputStream generateCsatDetalleReport(List<VwCsatDetalle> data) {
        Document document = new Document(PageSize.A4.rotate());
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        try {
            PdfWriter writer = PdfWriter.getInstance(document, out);
            writer.setPageEvent(new PageFooter());
            document.open();
            addHeader(document, "Detalle de Satisfacción del Cliente (Feedback)", data.size());

            PdfPTable table = new PdfPTable(5);
            table.setWidthPercentage(100);
            table.setWidths(new float[] { 2f, 2.5f, 1.2f, 3f, 1.5f });

            String[] headers = { "Cliente", "Asunto / Ticket", "Calificación", "Comentario / Feedback", "Fecha Cierre" };
            for (String h : headers) table.addCell(getHeaderCell(h));

            int i = 0;
            for (VwCsatDetalle d : data) {
                boolean z = (i % 2 == 1);
                table.addCell(getDataCell(d.getClienteNombre(), z));
                table.addCell(getDataCell("#" + d.getIdTicket() + " - " + d.getAsunto(), z));
                
                Font starFont = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 10, GOLD);
                PdfPCell starCell = new PdfPCell(new Phrase(d.getCalificacionSatisfaccion() + "★", starFont));
                if (z) starCell.setBackgroundColor(ZEBRA_ROW);
                starCell.setHorizontalAlignment(Element.ALIGN_CENTER);
                starCell.setPadding(8);
                starCell.setBorder(Rectangle.BOX);
                starCell.setBorderWidth(0.5f);
                starCell.setBorderColor(Color.BLACK);
                table.addCell(starCell);

                table.addCell(getDataCell(d.getComentarioCalificacion(), z));
                table.addCell(getDataCell(d.getFechaCierre() != null ? d.getFechaCierre().format(dateTimeFormatter) : "-", z));
                i++;
            }
            document.add(table);
            document.close();
        } catch (Exception e) { e.printStackTrace(); }
        return new ByteArrayInputStream(out.toByteArray());
    }

    public ByteArrayInputStream generateTicketDetailReport(Ticket ticket, List<InformeTrabajoTecnico> informes,
            List<HistorialEstado> historial, List<ComentarioTicket> comentarios,
            List<InventarioUsadoTicket> inventarioUsado) {
        Document document = new Document(PageSize.A4);
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        try {
            PdfWriter writer = PdfWriter.getInstance(document, out);
            writer.setPageEvent(new PageFooter());
            document.open();
            addHeader(document, "Reporte Detallado de Ticket #" + ticket.getIdTicket(), 1);

            Font sectionFont = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 12, BLUE_HEADER);
            Font labelFont = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 10, Color.DARK_GRAY);
            Font valueFont = FontFactory.getFont(FontFactory.HELVETICA, 10, Color.BLACK);
            DateTimeFormatter formatter = DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm");

            // --- SECCIÓN 1: INFORMACIÓN DEL CLIENTE ---
            document.add(new Paragraph("INFORMACIÓN DEL CLIENTE", sectionFont));
            PdfPTable clientTable = new PdfPTable(2);
            clientTable.setWidthPercentage(100);
            clientTable.setSpacingBefore(10);
            clientTable.setSpacingAfter(15);
            clientTable.addCell(
                    createLabelValueCell("Cliente:", getClienteNombre(ticket.getCliente()), labelFont, valueFont));
            clientTable.addCell(createLabelValueCell("Sucursal:",
                    ticket.getSucursal() != null ? ticket.getSucursal().getNombre() : "-", labelFont, valueFont));
            clientTable.addCell(createLabelValueCell("Contacto Email:", getClienteEmail(ticket.getCliente()), labelFont,
                    valueFont));
            clientTable.addCell(createLabelValueCell("Contacto Tel:", getClienteTelefono(ticket.getCliente()),
                    labelFont, valueFont));
            document.add(clientTable);

            // --- SECCIÓN 2: DETALLES DEL TICKET ---
            document.add(new Paragraph("DETALLES DEL REQUERIMIENTO", sectionFont));
            PdfPTable ticketTable = new PdfPTable(2);
            ticketTable.setWidthPercentage(100);
            ticketTable.setSpacingBefore(10);
            ticketTable.setSpacingAfter(15);
            ticketTable.addCell(createLabelValueCell("Asunto:", ticket.getAsunto(), labelFont, valueFont));
            ticketTable.addCell(createLabelValueCell("Estado:",
                    ticket.getEstadoItem() != null ? ticket.getEstadoItem().getNombre() : "-", labelFont, valueFont));
            ticketTable.addCell(createLabelValueCell("Servicio:",
                    ticket.getServicio() != null ? ticket.getServicio().getNombre() : "-", labelFont, valueFont));
            ticketTable.addCell(createLabelValueCell("Prioridad:",
                    ticket.getPrioridadItem() != null ? ticket.getPrioridadItem().getNombre() : "-", labelFont,
                    valueFont));
            ticketTable.addCell(createLabelValueCell("Fecha Creación:",
                    ticket.getFechaCreacion() != null ? ticket.getFechaCreacion().format(formatter) : "-", labelFont,
                    valueFont));
            ticketTable.addCell(createLabelValueCell("Fecha Cierre:",
                    ticket.getFechaCierre() != null ? ticket.getFechaCierre().format(formatter) : "-", labelFont,
                    valueFont));
            document.add(ticketTable);

            document.add(new Phrase("Descripción:", labelFont));
            Paragraph desc = new Paragraph(ticket.getDescripcion(), valueFont);
            desc.setSpacingAfter(15);
            document.add(desc);

            // --- SECCIÓN 3: HISTORIAL DE INFORMES TÉCNICOS ---
            if (informes != null && !informes.isEmpty()) {
                document.add(new Paragraph("HISTORIAL DE INFORMES TÉCNICOS", sectionFont));
                
                for (InformeTrabajoTecnico informe : informes) {
                    PdfPTable infoTable = new PdfPTable(1);
                    infoTable.setWidthPercentage(100);
                    infoTable.setSpacingBefore(10);
                    infoTable.setSpacingAfter(5);
                    infoTable.getDefaultCell().setBorderColor(new Color(200, 200, 200));

                    String headerText = "Informe #" + informe.getIdInforme() + " - " + 
                                       (informe.getFechaRegistro() != null ? informe.getFechaRegistro().format(formatter) : "S/F");
                    PdfPCell hCell = new PdfPCell(new Phrase(headerText, labelFont));
                    hCell.setBackgroundColor(ALTERNATE_ROW);
                    hCell.setPadding(5);
                    infoTable.addCell(hCell);

                    infoTable.addCell(createLabelValueCell("Técnico Responsable:",
                            getUserNombre(informe.getTecnico()), labelFont, valueFont));
                    infoTable.addCell(createLabelValueCell("Resultado:", informe.getResultado(), labelFont, valueFont));
                    infoTable.addCell(createLabelValueCell("Tiempo de Trabajo:",
                            informe.getTiempoTrabajoMinutos() != null ? informe.getTiempoTrabajoMinutos() + " min" : "-",
                            labelFont, valueFont));
                    infoTable.addCell(createLabelValueCell("Problemas Encontrados:", informe.getProblemasEncontrados(),
                            labelFont, valueFont));
                    infoTable.addCell(createLabelValueCell("Solución Aplicada:", informe.getSolucionAplicada(), labelFont,
                            valueFont));
                    infoTable.addCell(createLabelValueCell("Implementos Utilizados:", informe.getImplementosUsados(),
                            labelFont, valueFont));
                    infoTable.addCell(
                            createLabelValueCell("Pruebas Realizadas:", informe.getPruebasRealizadas(), labelFont,
                                    valueFont));

                    if ("NO_RESUELTO".equals(informe.getResultado())) {
                        infoTable.addCell(createLabelValueCell("Motivo No Resolución:", informe.getMotivoNoResolucion(),
                                labelFont, valueFont));
                    }

                    infoTable.addCell(createLabelValueCell("Comentario Técnico:", informe.getComentarioTecnico(), labelFont,
                            valueFont));
                    document.add(infoTable);
                }
                document.add(new Paragraph(" ", valueFont));
            }

            // 3. Historial de Estados
            if (historial != null && !historial.isEmpty()) {
                document.add(new Paragraph("HISTORIAL DE CAMBIOS", FontFactory.getFont(FontFactory.HELVETICA_BOLD, 12, DARK_BG)));
                PdfPTable hTable = new PdfPTable(3);
                hTable.setWidthPercentage(100);
                hTable.setSpacingBefore(10);
                hTable.setWidths(new float[]{1.5f, 2f, 3f});

                hTable.addCell(getHeaderCell("Fecha"));
                hTable.addCell(getHeaderCell("Nuevo Estado"));
                hTable.addCell(getHeaderCell("Observación"));

                int i = 0;
                for (HistorialEstado h : historial) {
                    boolean z = (i++ % 2 == 1);
                    hTable.addCell(getDataCell(h.getFechaCambio().format(dateTimeFormatter), z));
                    hTable.addCell(getBadgeCell(h.getEstadoNuevo().getNombre(), h.getEstadoNuevo().getCodigo(), z));
                    hTable.addCell(getDataCell(h.getObservacion(), z));
                }
                document.add(hTable);
            }

            document.close();
        } catch (Exception e) { e.printStackTrace(); }
        return new ByteArrayInputStream(out.toByteArray());
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
        } catch (Exception e) { return raw; }
    }
}
