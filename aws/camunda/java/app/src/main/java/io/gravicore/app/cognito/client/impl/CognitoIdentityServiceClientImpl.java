package io.gravicore.app.cognito.client.impl;

import io.gravicore.app.cognito.client.CognitoIdentityServiceClient;
import io.gravicore.app.cognito.model.CognitoGroup;
import io.gravicore.app.cognito.model.CognitoUser;
import org.apache.commons.lang3.mutable.MutableInt;
import org.apache.commons.lang3.mutable.MutableObject;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import software.amazon.awssdk.services.cognitoidentityprovider.CognitoIdentityProviderClient;
import software.amazon.awssdk.services.cognitoidentityprovider.model.*;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.function.Supplier;
import java.util.stream.Collectors;

@Component
public class CognitoIdentityServiceClientImpl implements CognitoIdentityServiceClient {

    private static final String MAX_RETRIES = "Max retries attempt reached";
    private static final int MAX_RETRY = 5;
    private static final int WAIT_CYCLE = 100;
    private static final String EMAIL = "email";
    private static final String LOGIN = "email";
    private static final String FIRST_NAME = "given_name";
    private static final String LAST_NAME = "family_name";

    @Value("${cognito.user.pool.id}")
    private String poolId;

    private final CognitoIdentityProviderClient client;

    @Autowired
    public CognitoIdentityServiceClientImpl(final CognitoIdentityProviderClient client) {
        this.client = client;
    }

    private void await() {
        try {
            Thread.sleep(WAIT_CYCLE);
        } catch (final Exception e) {
            /* ignored */
        }
    }

    private <T> T retry(final Supplier<T> supplier) {
        final MutableInt retry = new MutableInt(0);
        while (retry.getValue() < MAX_RETRY) {
            try {
                return supplier.get();
            } catch (final TooManyRequestsException e) {
                this.await();
                retry.add(1);
            }
        }
        throw new RuntimeException(MAX_RETRIES);
    }

    @Override
    public List<CognitoUser> getUsers() {
        return this.retry(() -> {
            final MutableObject<ListUsersResponse> mutable = new MutableObject<>(this.getUsersResponse(null));
            final List<CognitoUser> result = new ArrayList<>(this.getUsersConvert(mutable));
            while (mutable.getValue().paginationToken() != null) {
                mutable.setValue(this.getUsersResponse(mutable));
                result.addAll(this.getUsersConvert(mutable));
            }
            return result;
        });
    }

    private ListUsersResponse getUsersResponse(final MutableObject<ListUsersResponse> mutable) {
        return client.listUsers(ListUsersRequest.builder()
                .paginationToken(mutable != null && mutable.getValue() != null ? mutable.getValue().paginationToken() : null)
                .userPoolId(poolId)
            .build());
    }

    private List<CognitoUser> getUsersConvert(final MutableObject<ListUsersResponse> mutable) {
        final ListUsersResponse response = mutable.getValue();
        return response.users()
                .stream()
                .map(userType -> this.toOktaUser(userType.username(), userType.attributes()))
            .collect(Collectors.toList());
    }

    @Override
    public List<CognitoGroup> getGroups() {
        return this.retry(() -> {
            final MutableObject<ListGroupsResponse> mutable = new MutableObject<>(this.getGroupsResponse(null));
            final List<CognitoGroup> result = new ArrayList<>(this.getGroupsConvert(mutable));
            while (mutable.getValue().nextToken() != null) {
                mutable.setValue(this.getGroupsResponse(mutable));
                result.addAll(this.getGroupsConvert(mutable));
            }
            return result;
        });
    }

    private ListGroupsResponse getGroupsResponse(final MutableObject<ListGroupsResponse> mutable) {
        return client.listGroups(ListGroupsRequest.builder()
                .nextToken(mutable != null && mutable.getValue() != null ? mutable.getValue().nextToken() : null)
                .userPoolId(poolId)
            .build());
    }

    private List<CognitoGroup> getGroupsConvert(final MutableObject<ListGroupsResponse> mutable) {
        final ListGroupsResponse response = mutable.getValue();
        return response.groups()
                .stream()
                .map(this::toOktaGroup)
            .collect(Collectors.toList());
    }

    @Override
    public CognitoUser getUserById(final String userId) {
        final AdminGetUserResponse response = client.adminGetUser(AdminGetUserRequest.builder()
                .username(userId)
                .userPoolId(poolId)
            .build());
        return this.toOktaUser(response.username(), response.userAttributes());
    }

    @Override
    public List<CognitoUser> getUsersByGroupId(final String groupId) {
        return this.retry(() -> {
            final MutableObject<ListUsersInGroupResponse> mutable = new MutableObject<>(this.getUsersByGroupIdResponse(null, groupId));
            final List<CognitoUser> result = new ArrayList<>(this.getUsersByGroupIdConvert(mutable));
            while (mutable.getValue().nextToken() != null) {
                mutable.setValue(this.getUsersByGroupIdResponse(mutable, groupId));
                result.addAll(this.getUsersByGroupIdConvert(mutable));
            }
            return result;
        });
    }

    private ListUsersInGroupResponse getUsersByGroupIdResponse(final MutableObject<ListUsersInGroupResponse> mutable, final String groupId) {
        return client.listUsersInGroup(ListUsersInGroupRequest.builder()
                .nextToken(mutable != null && mutable.getValue() != null ? mutable.getValue().nextToken() : null)
                .groupName(groupId)
                .userPoolId(poolId)
            .build());
    }

    private List<CognitoUser> getUsersByGroupIdConvert(final MutableObject<ListUsersInGroupResponse> mutable) {
        final ListUsersInGroupResponse response = mutable.getValue();
        return response.users()
                .stream()
                .map(userType -> this.toOktaUser(userType.username(), userType.attributes()))
            .collect(Collectors.toList());
    }

    @Override
    public List<CognitoGroup> getUserGroups(final String userId) {
        return this.retry(() -> {
            final MutableObject<AdminListGroupsForUserResponse> mutable = new MutableObject<>(this.getUserGroupsResponse(null, userId));
            final List<CognitoGroup> result = new ArrayList<>(this.getUserGroupsConvert(mutable));
            while (mutable.getValue().nextToken() != null) {
                mutable.setValue(this.getUserGroupsResponse(mutable, userId));
                result.addAll(this.getUserGroupsConvert(mutable));
            }
            return result;
        });
    }

    private AdminListGroupsForUserResponse getUserGroupsResponse(final MutableObject<AdminListGroupsForUserResponse> mutable, final String userId) {
        return client.adminListGroupsForUser(AdminListGroupsForUserRequest.builder()
                .nextToken(mutable != null && mutable.getValue() != null ? mutable.getValue().nextToken() : null)
                .username(userId)
                .userPoolId(poolId)
            .build());
    }

    private List<CognitoGroup> getUserGroupsConvert(final MutableObject<AdminListGroupsForUserResponse> mutable) {
        final AdminListGroupsForUserResponse response = mutable.getValue();
        return response.groups()
                .stream()
                .map(this::toOktaGroup)
            .collect(Collectors.toList());
    }

    private CognitoGroup toOktaGroup(final GroupType group) {
        return CognitoGroup.builder()
            .id(group.groupName())
            .profile(CognitoGroup.Profile.builder()
                .name(group.groupName())
                .description(group.description())
                .build())
            .build();
    }

    private CognitoUser toOktaUser(final String username, final List<AttributeType> attributeTypes) {
        final Map<String, String> attributes = this.toAttributes(attributeTypes);
        return CognitoUser.builder()
            .id(username)
            .profile(CognitoUser.Profile.builder()
                .email(attributes.get(EMAIL))
                .login(attributes.get(LOGIN))
                .firstName(attributes.get(FIRST_NAME))
                .lastName(attributes.get(LAST_NAME))
                .build())
            .build();
    }

    private Map<String, String> toAttributes(final List<AttributeType> attributeTypes) {
        final Map<String, String> attributes = new HashMap<>();
        for (final AttributeType attribute : attributeTypes) {
            attributes.put(attribute.name(), attribute.value());
        }
        return attributes;
    }

}
