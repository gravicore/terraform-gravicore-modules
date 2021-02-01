package io.gravicore.app.custom.plugin;

import io.gravicore.app.custom.service.GroupService;
import io.gravicore.app.custom.service.UserService;
import org.camunda.bpm.engine.impl.identity.ReadOnlyIdentityProvider;
import org.camunda.bpm.engine.impl.interceptor.Session;
import org.camunda.bpm.engine.impl.interceptor.SessionFactory;
import org.springframework.stereotype.Service;

@Service
public class CustomIdentityProviderFactory implements SessionFactory {

    private final UserService userService;
    private final GroupService groupService;

    public CustomIdentityProviderFactory(final UserService userService, final GroupService groupService) {
        this.userService = userService;
        this.groupService = groupService;
    }

    @Override
    public Class<?> getSessionType() {
        return ReadOnlyIdentityProvider.class;
    }

    @Override
    public Session openSession() {
        return new CustomIdentityProvider(userService, groupService);
    }
}
