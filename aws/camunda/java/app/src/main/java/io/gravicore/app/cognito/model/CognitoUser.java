package io.gravicore.app.cognito.model;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
@Builder
@JsonIgnoreProperties(ignoreUnknown = true)
public class CognitoUser {

    private String id;
    private Profile profile;

    public String getUsername() {
        return profile.getLogin();
    }

    public String getFirstName() {
        return profile.getFirstName();
    }

    public String getLastName() {
        return profile.getLastName();
    }

    @Data
    @AllArgsConstructor
    @NoArgsConstructor
    @Builder
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class Profile {
        private String firstName;
        private String lastName;
        private String mobilePhone;
        private String secondEmail;
        private String login;
        private String email;
    }

}
