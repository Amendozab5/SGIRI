package com.apweb.backend.service;

import com.apweb.backend.model.VwCsatDetalle;
import com.apweb.backend.model.VwResumenTickets;
import com.apweb.backend.model.VwSlaTecnico;
import com.apweb.backend.model.VwCsatAnalisis;
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

    // Paleta de Colores Premium
    private static final Color BLUE_HEADER = new Color(30, 64, 175); // Azul Cobalto
    private static final Color TABLE_HEADER = new Color(59, 130, 246); // Azul Brillante
    private static final Color ALTERNATE_ROW = new Color(248, 250, 252); // Gris tenue

    private void addHeader(Document document, String title, int registerCount) throws DocumentException {
        // Tabla para el banner azul
        PdfPTable headerTable = new PdfPTable(1);
        headerTable.setWidthPercentage(100);

        PdfPCell banner = new PdfPCell();
        banner.setBackgroundColor(BLUE_HEADER);
        banner.setBorder(Rectangle.NO_BORDER);
        banner.setPadding(15);

        Font sgiriFont = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 22, Color.WHITE);
        Font titleFont = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 14, Color.WHITE);

        banner.addElement(new Phrase("SGIRI", sgiriFont));
        banner.addElement(new Phrase(title.toUpperCase(), titleFont));
        headerTable.addCell(banner);

        document.add(headerTable);

        // Metadata (Fecha y registros)
        PdfPTable metaTable = new PdfPTable(2);
        metaTable.setWidthPercentage(100);
        metaTable.setSpacingBefore(10);
        metaTable.setSpacingAfter(15);

        Font metaFont = FontFactory.getFont(FontFactory.HELVETICA, 9, Color.GRAY);
        String fecha = LocalDateTime.now().format(DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm"));

        PdfPCell leftCell = new PdfPCell(new Phrase("Generado: " + fecha, metaFont));
        leftCell.setBorder(Rectangle.NO_BORDER);

        PdfPCell rightCell = new PdfPCell(new Phrase("Total Registros: " + registerCount, metaFont));
        rightCell.setBorder(Rectangle.NO_BORDER);
        rightCell.setHorizontalAlignment(Element.ALIGN_RIGHT);

        metaTable.addCell(leftCell);
        metaTable.addCell(rightCell);
        document.add(metaTable);
    }

    private PdfPCell getHeaderCell(String text) {
        Font font = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 10, Color.WHITE);
        PdfPCell cell = new PdfPCell(new Phrase(text, font));
        cell.setBackgroundColor(TABLE_HEADER);
        cell.setPadding(8);
        cell.setHorizontalAlignment(Element.ALIGN_CENTER);
        cell.setBorderColor(Color.WHITE);
        return cell;
    }

    public ByteArrayInputStream generateTicketsReport(List<VwResumenTickets> data) {
        Document document = new Document(PageSize.A4.rotate()); // Horizontal para más espacio
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        try {
            PdfWriter.getInstance(document, out);
            document.open();
            addHeader(document, "Reporte Operativo de Gestión de Tickets", data.size());

            PdfPTable table = new PdfPTable(7);
            table.setWidthPercentage(100);
            table.setWidths(new float[] { 1, 3, 2, 1.5f, 1.5f, 1, 1 });

            String[] headers = { "ID", "Asunto", "Categoría", "Estado", "Prioridad", "CSAT", "T. Res" };
            for (String h : headers)
                table.addCell(getHeaderCell(h));

            int i = 0;
            for (VwResumenTickets t : data) {
                PdfPCell[] cells = {
                        new PdfPCell(new Phrase("#" + t.getIdTicket())),
                        new PdfPCell(new Phrase(t.getAsunto())),
                        new PdfPCell(new Phrase(t.getCategoria())),
                        new PdfPCell(new Phrase(t.getEstado())),
                        new PdfPCell(new Phrase(t.getPrioridad())),
                        new PdfPCell(new Phrase(
                                t.getCalificacionSatisfaccion() != null ? t.getCalificacionSatisfaccion() + "★" : "-")),
                        new PdfPCell(new Phrase(t.getTiempoResolucion() != null ? t.getTiempoResolucion() : "-"))
                };
                for (PdfPCell c : cells) {
                    if (i % 2 == 1)
                        c.setBackgroundColor(ALTERNATE_ROW);
                    c.setPadding(6);
                    c.setBorderColor(new Color(226, 232, 240));
                    table.addCell(c);
                }
                i++;
            }
            document.add(table);
            document.close();
        } catch (Exception e) {
            e.printStackTrace();
        }
        return new ByteArrayInputStream(out.toByteArray());
    }

    public ByteArrayInputStream generateSlaReport(List<VwSlaTecnico> data) {
        Document document = new Document(PageSize.A4);
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        try {
            PdfWriter.getInstance(document, out);
            document.open();
            addHeader(document, "Reporte de Cumplimiento de SLA por Técnico", data.size());

            PdfPTable table = new PdfPTable(5);
            table.setWidthPercentage(100);
            String[] headers = { "Técnico", "Total", "Resueltos", "SLA Cumplido", "Prom. Res." };
            for (String h : headers)
                table.addCell(getHeaderCell(h));

            int i = 0;
            for (VwSlaTecnico s : data) {
                PdfPCell[] cells = {
                        new PdfPCell(new Phrase(s.getTecnicoNombre())),
                        new PdfPCell(new Phrase(String.valueOf(s.getTotalTickets()))),
                        new PdfPCell(new Phrase(String.valueOf(s.getTicketsResueltos()))),
                        new PdfPCell(new Phrase(String.valueOf(s.getSlaCumplido()))),
                        new PdfPCell(new Phrase(s.getAvgResolucionHoras() + "h"))
                };
                for (PdfPCell c : cells) {
                    if (i % 2 == 1)
                        c.setBackgroundColor(ALTERNATE_ROW);
                    c.setPadding(6);
                    table.addCell(c);
                }
                i++;
            }
            document.add(table);
            document.close();
        } catch (Exception e) {
            e.printStackTrace();
        }
        return new ByteArrayInputStream(out.toByteArray());
    }

    public ByteArrayInputStream generateCsatReport(List<VwCsatAnalisis> data) {
        Document document = new Document(PageSize.A4);
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        try {
            PdfWriter.getInstance(document, out);
            document.open();
            addHeader(document, "Reporte de Satisfacción del Cliente (CSAT)", data.size());

            PdfPTable table = new PdfPTable(4);
            table.setWidthPercentage(100);
            String[] headers = { "Mes", "Respuestas", "Puntaje Prom.", "Tasa Positiva" };
            for (String h : headers)
                table.addCell(getHeaderCell(h));

            int i = 0;
            for (VwCsatAnalisis c : data) {
                PdfPCell[] cells = {
                        new PdfPCell(new Phrase(String.valueOf(c.getMes()))),
                        new PdfPCell(new Phrase(String.valueOf(c.getTotalRespuestas()))),
                        new PdfPCell(new Phrase(String.valueOf(c.getPuntajePromedio()))),
                        new PdfPCell(new Phrase(c.getTasaPositiva() + "%"))
                };
                for (PdfPCell cell : cells) {
                    if (i % 2 == 1)
                        cell.setBackgroundColor(ALTERNATE_ROW);
                    cell.setPadding(6);
                    table.addCell(cell);
                }
                i++;
            }
            document.add(table);
            document.close();
        } catch (Exception e) {
            e.printStackTrace();
        }
        return new ByteArrayInputStream(out.toByteArray());
    }

    public ByteArrayInputStream generateCsatDetalleReport(List<VwCsatDetalle> data) {
        Document document = new Document(PageSize.A4.rotate());
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        try {
            PdfWriter.getInstance(document, out);
            document.open();
            addHeader(document, "Detalle de Satisfacción del Cliente (Feedback)", data.size());

            PdfPTable table = new PdfPTable(5);
            table.setWidthPercentage(100);
            table.setWidths(new float[] { 2f, 2.5f, 1.2f, 3f, 1.5f });

            String[] headers = { "Cliente", "Asunto / Ticket", "Calificación", "Comentario / Feedback",
                    "Fecha Cierre" };
            for (String h : headers)
                table.addCell(getHeaderCell(h));

            DateTimeFormatter formatter = DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm");
            int i = 0;
            for (VwCsatDetalle d : data) {
                PdfPCell[] cells = {
                        new PdfPCell(new Phrase(d.getClienteNombre())),
                        new PdfPCell(new Phrase("#" + d.getIdTicket() + " - " + d.getAsunto())),
                        new PdfPCell(new Phrase(d.getCalificacionSatisfaccion() + "★")),
                        new PdfPCell(new Phrase(
                                d.getComentarioCalificacion() != null ? d.getComentarioCalificacion() : "-")),
                        new PdfPCell(
                                new Phrase(d.getFechaCierre() != null ? d.getFechaCierre().format(formatter) : "-"))
                };
                for (PdfPCell c : cells) {
                    if (i % 2 == 1)
                        c.setBackgroundColor(ALTERNATE_ROW);
                    c.setPadding(6);
                    c.setBorderColor(new Color(226, 232, 240));
                    table.addCell(c);
                }
                i++;
            }
            document.add(table);
            document.close();
        } catch (Exception e) {
            e.printStackTrace();
        }
        return new ByteArrayInputStream(out.toByteArray());
    }
}
