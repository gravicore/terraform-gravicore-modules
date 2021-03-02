package io.gravicore.app.custom.entity;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.camunda.bpm.engine.identity.Group;

@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class CustomGroup implements Group {
    private String id;
    private String name;
    private String type;
}
