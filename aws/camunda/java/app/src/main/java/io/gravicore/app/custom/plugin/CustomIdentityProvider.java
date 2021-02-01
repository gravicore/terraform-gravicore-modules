package io.gravicore.app.custom.plugin;

import io.gravicore.app.custom.entity.CustomGroup;
import io.gravicore.app.custom.entity.CustomUser;
import io.gravicore.app.custom.service.GroupService;
import io.gravicore.app.custom.service.UserService;
import org.camunda.bpm.engine.BadUserRequestException;
import org.camunda.bpm.engine.identity.*;
import org.camunda.bpm.engine.impl.context.Context;
import org.camunda.bpm.engine.impl.identity.ReadOnlyIdentityProvider;
import org.camunda.bpm.engine.impl.interceptor.CommandContext;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.Collection;
import java.util.List;

@Service
public class CustomIdentityProvider implements ReadOnlyIdentityProvider {

    private final UserService userService;
    private final GroupService groupService;

    public CustomIdentityProvider(final UserService userService, final GroupService groupService) {
        this.userService = userService;
        this.groupService = groupService;
    }

    @Override
    public User findUserById(final String userId) {
        return userService.findById(userId);
    }

    @Override
    public UserQuery createUserQuery() {
        return new CustomUserQuery(Context.getProcessEngineConfiguration()
                .getCommandExecutorTxRequired());
    }

    @Override
    public UserQuery createUserQuery(final CommandContext context) {
        return new CustomUserQuery(context.getProcessEngineConfiguration()
                .getCommandExecutorTxRequired());
    }

    @Override
    public NativeUserQuery createNativeUserQuery() {
        throw new BadUserRequestException("Unsupported");
    }

    public long findUserCountByQueryCriteria(final CustomUserQuery query) {
        return findUserByQueryCriteria(query).size();
    }

    public List<User> findUserByQueryCriteria(final CustomUserQuery query) {
        final Collection<CustomUser> customUsers = userService.findAll();
        if (query.getGroupId() != null) {
            return new ArrayList<>(userService.findByGroupId(query.getGroupId()));
        }
        if (query.getId() != null) {
            customUsers.removeIf(customUser ->
                    !customUser.getId().equals(query.getId()));
        }
        if (query.getFirstName() != null) {
            customUsers.removeIf(customUser ->
                    !customUser.getFirstName().equalsIgnoreCase(query.getFirstName()));
        }
        if (query.getLastName() != null) {
            customUsers.removeIf(customUser ->
                    !customUser.getLastName().equals(query.getLastName()));
        }
        if (query.getEmail() != null) {
            customUsers.removeIf(customUser ->
                    !customUser.getEmail().equals(query.getEmail()));
        }
        return new ArrayList<>(customUsers);

    }

    @Override
    public boolean checkPassword(final String userId, final String password) {
        if (userId == null || password == null || userId.isEmpty() || password.isEmpty()) {
            return false;
        }

        final User user = this.findUserById(userId);
        if (user == null) {
            return false;
        }

        return user.getPassword().equals(password);
    }

    @Override
    public Group findGroupById(final String groupId) {
        return groupService.findById(groupId);
    }

    @Override
    public GroupQuery createGroupQuery() {
        return new CustomGroupQuery(Context.getProcessEngineConfiguration()
                .getCommandExecutorTxRequired());
    }

    @Override
    public GroupQuery createGroupQuery(final CommandContext context) {
        return new CustomGroupQuery(context.getProcessEngineConfiguration()
                .getCommandExecutorTxRequired());
    }

    public long findGroupCountByQueryCriteria(final CustomGroupQuery query) {
        return findGroupByQueryCriteria(query).size();
    }

    public List<Group> findGroupByQueryCriteria(final CustomGroupQuery query) {
        final Collection<CustomGroup> customGroups = groupService.findAll();
        if (query.getUserId() != null) {
            final List<CustomGroup> userCustomGroups = groupService.getGroupsForUser(query.getUserId());
            return new ArrayList<>(userCustomGroups);
        } else {
            if (query.getId() != null) {
                customGroups.removeIf(customGroup ->
                        !customGroup.getId().equals(query.getId()));
            }
            if (query.getName() != null) {
                customGroups.removeIf(customGroup ->
                        !customGroup.getName().equals(query.getName()));
            }
            if (query.getType() != null) {
                customGroups.removeIf(customGroup ->
                        !customGroup.getType().equals(query.getType()));
            }
        }
        return new ArrayList<>(customGroups);
    }

    @Override
    public Tenant findTenantById(final String tenantId) {
        return null;
    }

    @Override
    public TenantQuery createTenantQuery() {
        return new CustomTenantQuery(Context.getProcessEngineConfiguration().getCommandExecutorTxRequired());
    }

    @Override
    public TenantQuery createTenantQuery(final CommandContext context) {
        return new CustomTenantQuery();
    }

    @Override
    public void flush() { }

    @Override
    public void close() { }
}
