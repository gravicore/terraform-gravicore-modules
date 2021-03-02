package io.gravicore.app;

import com.timgroup.statsd.NonBlockingStatsDClientBuilder;
import com.timgroup.statsd.StatsDClient;

import org.apache.commons.lang3.StringUtils;
import org.camunda.bpm.engine.impl.plugin.AdministratorAuthorizationPlugin;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.web.servlet.ServletContextInitializer;
import org.springframework.context.annotation.*;
import org.springframework.core.annotation.Order;
import org.springframework.core.env.Environment;
import org.springframework.core.type.AnnotatedTypeMetadata;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;

@EnableWebSecurity
@SpringBootApplication
public class Application {

    private static final String CSRF_PREVENTION_FILTER = "CsrfPreventionFilter";

    @Value("${camunda.admin.user.id}")
    private String adminUsername;
    @Value("${camunda.admin.group.name}")
    private String adminGroupName;
    @Value("${dd.agent.host:}")
    private String statsdHost;
    @Value("${dd.statsd.agent.prefix:}")
    private String statsdPrefix;
    @Value("${dd.statsd.agent.port:}")
    private Integer statsdPort;

    public static void main(String... args) {
        SpringApplication.run(Application.class, args);
    }

    @Bean
    @Primary
    @Order(Integer.MAX_VALUE - 1)
    public AdministratorAuthorizationPlugin administratorAuthorizationPlugin() {
        final AdministratorAuthorizationPlugin plugin = new AdministratorAuthorizationPlugin();
        plugin.setAdministratorUserName(adminUsername);
        plugin.setAdministratorGroupName(adminGroupName);
        return plugin;
    }


    @Bean
    public ServletContextInitializer csrfOverwrite() {
        return servletContext -> servletContext.addFilter(CSRF_PREVENTION_FILTER,
                (request, response, chain) -> chain.doFilter(request, response));
    }

    @Bean
    @Conditional(HasDataDog.class)
    public StatsDClient statsDClient() {
        return new NonBlockingStatsDClientBuilder()
                .prefix(statsdPrefix)
                .hostname(statsdHost)
                .port(statsdPort)
            .build();
    }

    public static class HasDataDog implements Condition {
        @Override
        public boolean matches(final ConditionContext context, final AnnotatedTypeMetadata metadata) {
            final Environment env = context.getEnvironment();
            return StringUtils.isNoneBlank(env.getProperty("dd.agent.host"));
        }
    }

}