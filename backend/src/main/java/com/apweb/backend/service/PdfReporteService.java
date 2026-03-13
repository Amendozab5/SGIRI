package com.apweb.backend.service;

import com.apweb.backend.model.VwCsatDetalle;
import com.apweb.backend.model.VwResumenTickets;
import com.apweb.backend.model.VwSlaTecnico;
import com.apweb.backend.model.VwCsatAnalisis;
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

    public ByteArrayInputStream generateTicketDetailReport(Ticket ticket, List<InformeTrabajoTecnico> informes,
            List<HistorialEstado> historial, List<ComentarioTicket> comentarios,
            List<InventarioUsadoTicket> inventarioUsado) {
        Document document = new Document(PageSize.A4);
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        try {
            PdfWriter.getInstance(document, out);
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

            // --- SECCIÓN 4: HISTORIAL DE ESTADOS ---
            if (historial != null && !historial.isEmpty()) {
                document.add(new Paragraph("HISTORIAL DE ESTADOS", sectionFont));
                PdfPTable histTable = new PdfPTable(3);
                histTable.setWidthPercentage(100);
                histTable.setSpacingBefore(10);
                histTable.setSpacingAfter(15);
                histTable.setWidths(new float[] { 1, 1.5f, 2 });

                histTable.addCell(getHeaderCell("Fecha"));
                histTable.addCell(getHeaderCell("Estado"));
                histTable.addCell(getHeaderCell("Observación"));

                for (HistorialEstado h : historial) {
                    histTable.addCell(new Phrase(h.getFechaCambio().format(formatter), valueFont));
                    histTable.addCell(new Phrase(h.getEstadoNuevo() != null ? h.getEstadoNuevo().getNombre() : "-",
                            valueFont));
                    histTable.addCell(new Phrase(h.getObservacion(), valueFont));
                }
                document.add(histTable);
            }

            // --- SECCIÓN 5: REPUESTOS / INVENTARIO ---
            if (inventarioUsado != null && !inventarioUsado.isEmpty()) {
                document.add(new Paragraph("REPUESTOS Y MATERIALES UTILIZADOS", sectionFont));
                PdfPTable invTable = new PdfPTable(3);
                invTable.setWidthPercentage(100);
                invTable.setSpacingBefore(10);
                invTable.setSpacingAfter(15);
                invTable.setWidths(new float[] { 3, 1, 2 });

                invTable.addCell(getHeaderCell("Ítem / Repuesto"));
                invTable.addCell(getHeaderCell("Cant."));
                invTable.addCell(getHeaderCell("Fecha Uso"));

                for (InventarioUsadoTicket u : inventarioUsado) {
                    invTable.addCell(
                            new Phrase(u.getInventario() != null ? u.getInventario().getNombre() : "-", valueFont));
                    invTable.addCell(new Phrase(String.valueOf(u.getCantidad()), valueFont));
                    invTable.addCell(new Phrase(
                            u.getFechaRegistro() != null ? u.getFechaRegistro().format(formatter) : "-", valueFont));
                }
                document.add(invTable);
            }

            // --- SECCIÓN 6: CONVERSACIÓN DEL TICKET ---
            if (comentarios != null && !comentarios.isEmpty()) {
                document.add(new Paragraph("CONVERSACIÓN DEL TICKET (CHAT)", sectionFont));
                PdfPTable chatTable = new PdfPTable(3);
                chatTable.setWidthPercentage(100);
                chatTable.setSpacingBefore(10);
                chatTable.setSpacingAfter(15);
                chatTable.setWidths(new float[] { 1.5f, 1.5f, 4 });

                chatTable.addCell(getHeaderCell("Fecha"));
                chatTable.addCell(getHeaderCell("Usuario"));
                chatTable.addCell(getHeaderCell("Mensaje"));

                for (ComentarioTicket c : comentarios) {
                    chatTable.addCell(new Phrase(
                            c.getFechaCreacion() != null ? c.getFechaCreacion().format(formatter) : "-", valueFont));
                    chatTable.addCell(new Phrase(getUserNombre(c.getUsuario()), valueFont));
                    chatTable.addCell(new Phrase(c.getComentario(), valueFont));
                }
                document.add(chatTable);
            }

            document.close();
        } catch (Exception e) {
            e.printStackTrace();
        }
        return new ByteArrayInputStream(out.toByteArray());
    }

    private PdfPCell createLabelValueCell(String label, String value, Font labelFont, Font valueFont) {
        PdfPCell cell = new PdfPCell();
        cell.setBorder(Rectangle.NO_BORDER);
        cell.setPadding(4);
        Phrase p = new Phrase();
        p.add(new Chunk(label + " ", labelFont));
        p.add(new Chunk(value != null ? value : "-", valueFont));
        cell.addElement(p);
        return cell;
    }

    private String getClienteNombre(Cliente cliente) {
        if (cliente == null || cliente.getPersona() == null)
            return "-";
        String n = cliente.getPersona().getNombre() != null ? cliente.getPersona().getNombre() : "";
        String a = cliente.getPersona().getApellido() != null ? cliente.getPersona().getApellido() : "";
        return (n + " " + a).trim();
    }

    private String getClienteEmail(Cliente cliente) {
        if (cliente == null || cliente.getPersona() == null)
            return "-";
        return cliente.getPersona().getCorreo() != null ? cliente.getPersona().getCorreo() : "-";
    }

    private String getClienteTelefono(Cliente cliente) {
        if (cliente == null || cliente.getPersona() == null)
            return "-";
        return cliente.getPersona().getCelular() != null ? cliente.getPersona().getCelular() : "-";
    }

    private String getUserNombre(User user) {
        if (user == null)
            return "-";
        if (user.getPersona() == null)
            return user.getUsername();
        String n = user.getPersona().getNombre() != null ? user.getPersona().getNombre() : "";
        String a = user.getPersona().getApellido() != null ? user.getPersona().getApellido() : "";
        String completo = (n + " " + a).trim();
        return completo.isEmpty() ? user.getUsername() : completo;
    }
}
