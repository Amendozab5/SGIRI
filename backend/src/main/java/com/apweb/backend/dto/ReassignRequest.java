package com.apweb.backend.dto;

import lombok.Data;

@Data
public class ReassignRequest {
    private Integer userId;
    private String notaReasignacion;
}
