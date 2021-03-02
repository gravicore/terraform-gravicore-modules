package io.gravicore.app.custom.service;

import io.gravicore.app.cognito.client.CognitoIdentityServiceClient;
import io.gravicore.app.cognito.model.CognitoGroup;
import io.gravicore.app.custom.entity.CustomGroup;
import org.springframework.stereotype.Service;

import java.util.Collection;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class GroupService {

    private final CognitoIdentityServiceClient cognitoIdentityServiceClient;

    public GroupService(final CognitoIdentityServiceClient cognitoIdentityServiceClient) {
        this.cognitoIdentityServiceClient = cognitoIdentityServiceClient;
    }

    public CustomGroup findById(final String id) {
        return CustomGroup.builder()
                .id(id)
                .name(id)
                .type("")
            .build();
    }

    private CustomGroup fromOktaGroup(final CognitoGroup cognitoGroup){
        return CustomGroup.builder()
                .id(cognitoGroup.getId())
                .name(cognitoGroup.getRoleName())
                .type("")
            .build();
    }

    public Collection<CustomGroup> findAll() {
        return this.cognitoIdentityServiceClient
                .getGroups()
                .stream()
                .map(this::fromOktaGroup)
            .collect(Collectors.toList());
    }



    public List<CustomGroup> getGroupsForUser(final String userId){
        final List<CognitoGroup> cognitoGroups = this.cognitoIdentityServiceClient.getUserGroups(userId);
        return cognitoGroups.stream()
                .map(this::fromOktaGroup)
            .collect(Collectors.toList());
    }
}
