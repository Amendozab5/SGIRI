package com.apweb.backend.service;

import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

@Service
public class FileStorageService {

    private final CloudinaryService cloudinaryService;

    public FileStorageService(CloudinaryService cloudinaryService) {
        this.cloudinaryService = cloudinaryService;
    }

    public String save(MultipartFile file, String username) {
        // En lugar de guardar en disco, subimos a la nube de Cloudinary
        // Retornamos la URL segura que genera Cloudinary para guardarla en la BD
        return cloudinaryService.upload(file, "sgiri_uploads");
    }
}