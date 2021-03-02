package io.gravicore.app.custom.plugin;

import org.camunda.bpm.engine.identity.Tenant;
import org.camunda.bpm.engine.impl.Page;
import org.camunda.bpm.engine.impl.TenantQueryImpl;
import org.camunda.bpm.engine.impl.interceptor.CommandContext;
import org.camunda.bpm.engine.impl.interceptor.CommandExecutor;

import java.util.Collections;
import java.util.List;

public class CustomTenantQuery extends TenantQueryImpl {

    public CustomTenantQuery() {
        super();
    }

    public CustomTenantQuery(final CommandExecutor executor) {
        super(executor);
    }

    @Override
    public long executeCount(final CommandContext context) {
        return 0;
    }

    @Override
    public List<Tenant> executeList(final CommandContext context, final Page page) {
        return Collections.emptyList();
    }
}
