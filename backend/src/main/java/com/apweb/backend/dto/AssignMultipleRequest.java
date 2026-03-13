package com.apweb.backend.dto;

import lombok.Data;
import java.util.List;

@Data
public class AssignMultipleRequest {
    private List<Integer> userIds;
    private String groupCode;
}
