package com.apweb.backend.service;

import com.apweb.backend.dto.ClienteCreateRequest;
import com.apweb.backend.model.Cliente;
import org.apache.poi.ss.usermodel.*;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.io.InputStream;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;

@Service
public class ExcelImportService {

    private static final Logger log = LoggerFactory.getLogger(ExcelImportService.class);

    @Autowired
    private PersonnelService personnelService;

    public List<Cliente> importClientesExcel(MultipartFile file, Integer idSucursal) throws IOException {
        List<Cliente> createdClientes = new ArrayList<>();
        
        try (InputStream is = file.getInputStream(); Workbook workbook = new XSSFWorkbook(is)) {
            Sheet sheet = workbook.getSheetAt(0);
            Iterator<Row> rows = sheet.iterator();

            int rowNumber = 0;
            while (rows.hasNext()) {
                Row currentRow = rows.next();

                // Skip Header
                if (rowNumber == 0) {
                    rowNumber++;
                    continue;
                }

                try {
                    ClienteCreateRequest request = new ClienteCreateRequest();
                    request.setIdSucursal(idSucursal);

                    // Col 0: Cedula
                    request.setCedula(getCellValueAsString(currentRow.getCell(0)));
                    if (request.getCedula() == null || request.getCedula().isBlank()) continue;

                    // Col 1: Nombre
                    request.setNombre(getCellValueAsString(currentRow.getCell(1)));
                    
                    // Col 2: Apellido
                    request.setApellido(getCellValueAsString(currentRow.getCell(2)));
                    
                    // Col 3: Correo
                    request.setCorreo(getCellValueAsString(currentRow.getCell(3)));
                    
                    // Col 4: Celular
                    request.setCelular(getCellValueAsString(currentRow.getCell(4)));

                    // Col 5: Fecha Inicio (Optional)
                    request.setFechaInicioContrato(getCellValueAsLocalDate(currentRow.getCell(5)));
                    
                    // Col 6: Fecha Fin (Optional)
                    request.setFechaFinContrato(getCellValueAsLocalDate(currentRow.getCell(6)));

                    Cliente creado = personnelService.crearCliente(request);
                    createdClientes.add(creado);
                    
                } catch (Exception e) {
                    log.error("Error importando fila {}: {}", rowNumber, e.getMessage());
                }
                rowNumber++;
            }
        }
        
        return createdClientes;
    }

    private String getCellValueAsString(Cell cell) {
        if (cell == null) return null;
        switch (cell.getCellType()) {
            case STRING: return cell.getStringCellValue();
            case NUMERIC: 
                if (DateUtil.isCellDateFormatted(cell)) return cell.getDateCellValue().toString();
                return String.valueOf((long) cell.getNumericCellValue());
            case BOOLEAN: return String.valueOf(cell.getBooleanCellValue());
            default: return null;
        }
    }

    private LocalDate getCellValueAsLocalDate(Cell cell) {
        if (cell == null) return null;
        if (cell.getCellType() == CellType.NUMERIC && DateUtil.isCellDateFormatted(cell)) {
            return cell.getDateCellValue().toInstant().atZone(ZoneId.systemDefault()).toLocalDate();
        }
        return null;
    }
}
