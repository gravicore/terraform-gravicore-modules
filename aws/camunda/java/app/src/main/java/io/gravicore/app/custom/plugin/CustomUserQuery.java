package io.gravicore.app.custom.plugin;

import org.camunda.bpm.engine.identity.User;
import org.camunda.bpm.engine.impl.Page;
import org.camunda.bpm.engine.impl.UserQueryImpl;
import org.camunda.bpm.engine.impl.interceptor.CommandContext;
import org.camunda.bpm.engine.impl.interceptor.CommandExecutor;

import java.util.List;

public class CustomUserQuery extends UserQueryImpl {

    public CustomUserQuery(final CommandExecutor executor) {
        super(executor);
    }

    @Override
    public long executeCount(final CommandContext context) {
        final CustomIdentityProvider provider = this.getCustomIdentityProvider(context);
        return provider.findUserCountByQueryCriteria(this);
    }

    @Override
    public List<User> executeList(final CommandContext context, final Page page) {
        final CustomIdentityProvider provider = this.getCustomIdentityProvider(context);
        return Pagination.getPage(provider.findUserByQueryCriteria(this), page);
    }

    protected CustomIdentityProvider getCustomIdentityProvider(final CommandContext context) {
        return (CustomIdentityProvider) context.getReadOnlyIdentityProvider();
    }
}
