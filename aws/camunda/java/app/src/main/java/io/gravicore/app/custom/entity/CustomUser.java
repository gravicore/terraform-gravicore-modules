package io.gravicore.app.custom.entity;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.camunda.bpm.engine.identity.User;

import java.util.List;

@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class CustomUser implements User {
    private String id;
    private String firstName;
    private String lastName;
    private String email;
    private String password;
    private List<CustomGroup> groups;
}
