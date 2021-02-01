package io.gravicore.app.custom.plugin;

import org.camunda.bpm.engine.identity.Group;
import org.camunda.bpm.engine.impl.GroupQueryImpl;
import org.camunda.bpm.engine.impl.Page;
import org.camunda.bpm.engine.impl.interceptor.CommandContext;
import org.camunda.bpm.engine.impl.interceptor.CommandExecutor;

import java.util.List;

public class CustomGroupQuery extends GroupQueryImpl {

    public CustomGroupQuery(final CommandExecutor executor) {
        super(executor);
    }

    @Override
    public long executeCount(final CommandContext context) {
        final CustomIdentityProvider provider = this.getCustomIdentityProvider(context);
        return provider.findGroupCountByQueryCriteria(this);
    }

    @Override
    public List<Group> executeList(final CommandContext context, final Page page) {
        final CustomIdentityProvider provider = this.getCustomIdentityProvider(context);
        return Pagination.getPage(provider.findGroupByQueryCriteria(this), page);
    }

    protected CustomIdentityProvider getCustomIdentityProvider(final CommandContext context) {
        return (CustomIdentityProvider) context.getReadOnlyIdentityProvider();
    }
}
