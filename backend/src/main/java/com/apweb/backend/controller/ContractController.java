package com.apweb.backend.controller;

import com.apweb.backend.model.Empresa;
import com.apweb.backend.service.ContractService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

@CrossOrigin(origins = "http://localhost:4200", maxAge = 3600, allowCredentials = "true")
@RestController
@RequestMapping("/api/contracts")
public class ContractController {

    @Autowired
    private ContractService contractService;

    @PostMapping("/upload")
    public ResponseEntity<Empresa> uploadContract(@RequestParam("file") MultipartFile file) {
        return ResponseEntity.ok(contractService.processContractUpload(file));
    }
}
