package com.apweb.backend.service;

import com.cloudinary.Cloudinary;
import com.cloudinary.utils.ObjectUtils;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.Map;

@Service
public class CloudinaryService {

    private final Cloudinary cloudinary;

    public CloudinaryService(Cloudinary cloudinary) {
        this.cloudinary = cloudinary;
    }

    /**
     * Sube un archivo a Cloudinary y retorna la URL segura.
     * @param file El archivo multipart
     * @param folder La carpeta en Cloudinary (ej: "perfiles", "documentos")
     * @return URL pública del archivo
     */
    public String upload(MultipartFile file, String folder) {
        try {
            String originalName = file.getOriginalFilename();
            String resourceType = "auto";
            String publicId = java.util.UUID.randomUUID().toString();
            
            // Si es PDF, usamos "raw" para evitar restricciones de seguridad de Cloudinary
            // pero incluimos la extensión en el public_id para que el navegador lo reconozca
            if (originalName != null && originalName.toLowerCase().endsWith(".pdf")) {
                resourceType = "raw";
                publicId += ".pdf";
            }

            Map<?, ?> uploadResult = cloudinary.uploader().upload(file.getBytes(),
                    ObjectUtils.asMap(
                        "folder", folder,
                        "resource_type", resourceType,
                        "public_id", publicId
                    ));
            return uploadResult.get("secure_url").toString();
        } catch (IOException e) {
            throw new RuntimeException("Error al subir archivo a Cloudinary: " + e.getMessage());
        }
    }

    /**
     * Elimina un archivo de Cloudinary dado su URL.
     * Útil para cuando un usuario cambia su foto antigua por una nueva.
     * @param url URL completa del archivo
     */
    public void delete(String url) {
        if (url == null || !url.contains("cloudinary.com")) return;
        try {
            // Extraer el public_id de la URL. Ej: .../v1234/folder/name.jpg -> folder/name
            String publicId = extractPublicId(url);
            cloudinary.uploader().destroy(publicId, ObjectUtils.emptyMap());
        } catch (IOException e) {
            System.err.println("No se pudo eliminar el archivo de Cloudinary: " + e.getMessage());
        }
    }

    private String extractPublicId(String url) {
        if (url == null) return null;
        
        // Determinar si es un recurso "raw" (los raw mantienen la extensión en el public_id)
        boolean isRaw = url.contains("/raw/");
        
        String[] parts = url.split("/");
        String fileNameWithExt = parts[parts.length - 1];
        
        // Para imágenes quitamos extensión, para raw la mantenemos
        String publicIdBase = isRaw ? fileNameWithExt : 
            (fileNameWithExt.contains(".") ? fileNameWithExt.substring(0, fileNameWithExt.lastIndexOf('.')) : fileNameWithExt);
        
        // Buscar dónde empieza la ruta después del tipo de subida (upload) y la versión (v1234...)
        int uploadIndex = -1;
        for (int i = 0; i < parts.length; i++) {
            if (parts[i].equals("upload")) {
                uploadIndex = i;
                break;
            }
        }
        
        if (uploadIndex != -1 && parts.length > uploadIndex + 2) {
            StringBuilder sb = new StringBuilder();
            // Empezamos en uploadIndex + 2 para saltarnos la versión (vNNNNN)
            for (int i = uploadIndex + 2; i < parts.length - 1; i++) {
                sb.append(parts[i]).append("/");
            }
            sb.append(publicIdBase);
            return sb.toString();
        }
        
        return publicIdBase;
    }

    /**
     * Sube un PDF como bytes crudos a Cloudinary y retorna la URL segura.
     * Útil para subir PDFs generados en memoria (ej. Hoja de Servicio).
     */
    public String uploadPdf(byte[] pdfBytes, String folder, String fileName) {
        try {
            Map<?, ?> uploadResult = cloudinary.uploader().upload(pdfBytes,
                    ObjectUtils.asMap(
                        "folder", folder,
                        "resource_type", "raw",
                        "public_id", folder + "/" + fileName,
                        "use_filename", true,
                        "unique_filename", false
                    ));
            return uploadResult.get("secure_url").toString();
        } catch (IOException e) {
            throw new RuntimeException("Error al subir PDF a Cloudinary: " + e.getMessage());
        }
    }
}
