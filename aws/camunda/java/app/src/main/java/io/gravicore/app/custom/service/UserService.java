package io.gravicore.app.custom.service;

import io.gravicore.app.cognito.client.CognitoIdentityServiceClient;
import io.gravicore.app.custom.entity.CustomUser;
import io.gravicore.app.cognito.model.CognitoUser;
import org.springframework.stereotype.Service;

import java.util.Collection;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class UserService {

    private final CognitoIdentityServiceClient cognitoIdentityServiceClient;

    public UserService(CognitoIdentityServiceClient cognitoIdentityServiceClient) {
        this.cognitoIdentityServiceClient = cognitoIdentityServiceClient;
    }

    private CustomUser fromOktaUser(final CognitoUser cognitoUser){
        return CustomUser.builder()
                .id(cognitoUser.getId())
                .email(cognitoUser.getUsername())
                .firstName(cognitoUser.getFirstName())
                .lastName(cognitoUser.getLastName())
            .build();
    }

    public CustomUser findById(String id) {
        return this.fromOktaUser(this.cognitoIdentityServiceClient.getUserById(id));
    }

    public Collection<CustomUser> findAll() {
        final List<CognitoUser> cognitoUsers = this.cognitoIdentityServiceClient.getUsers();
        return cognitoUsers.stream()
                .map(this::fromOktaUser)
            .collect(Collectors.toList());
    }

    public Collection<CustomUser> findByGroupId(String groupId){
        return this.cognitoIdentityServiceClient
            .getUsersByGroupId(groupId).stream()
                .map(this::fromOktaUser)
            .collect(Collectors.toList());
    }

}
