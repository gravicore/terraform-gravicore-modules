package io.gravicore.app.cognito.client;


import io.gravicore.app.cognito.model.CognitoGroup;
import io.gravicore.app.cognito.model.CognitoUser;
import java.util.List;

public interface CognitoIdentityServiceClient {

    List<CognitoUser> getUsers();
    List<CognitoGroup> getGroups();
    CognitoUser getUserById(String userId);
    List<CognitoUser> getUsersByGroupId(String groupId);
    List<CognitoGroup> getUserGroups(String userId);

}
