package com.apweb.backend.payload.request;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class CommentRequest {
    @NotBlank
    private String comentario;

    private Boolean esInterno = false;
}
