package io.gravicore.loc.cognito.client;


import io.gravicore.loc.cognito.model.CognitoGroup;
import io.gravicore.loc.cognito.model.CognitoUser;
import java.util.List;

public interface CognitoIdentityServiceClient {

    List<CognitoUser> getUsers();
    List<CognitoGroup> getGroups();
    CognitoUser getUserById(String userId);
    List<CognitoUser> getUsersByGroupId(String groupId);
    List<CognitoGroup> getUserGroups(String userId);

}
