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
            Map<?, ?> uploadResult = cloudinary.uploader().upload(file.getBytes(),
                    ObjectUtils.asMap("folder", folder));
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
        // Lógica simple para extraer el ID público de una URL de Cloudinary
        // Ejemplo: https://res.cloudinary.com/demo/image/upload/v1234/folder/id.jpg
        String[] parts = url.split("/");
        String fileNameWithExt = parts[parts.length - 1];
        String fileName = fileNameWithExt.substring(0, fileNameWithExt.lastIndexOf('.'));
        
        // Si hay carpetas, están después de "upload/"
        int uploadIndex = -1;
        for (int i = 0; i < parts.length; i++) {
            if (parts[i].equals("upload")) {
                uploadIndex = i;
                break;
            }
        }
        
        if (uploadIndex != -1 && parts.length > uploadIndex + 2) {
            // Hay carpetas entre vNNNNN y el nombre de archivo
            StringBuilder sb = new StringBuilder();
            for (int i = uploadIndex + 2; i < parts.length - 1; i++) {
                sb.append(parts[i]).append("/");
            }
            sb.append(fileName);
            return sb.toString();
        }
        
        return fileName;
    }
}
