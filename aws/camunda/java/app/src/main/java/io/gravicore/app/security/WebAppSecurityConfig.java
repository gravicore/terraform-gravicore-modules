package io.gravicore.app.security;

import org.camunda.bpm.webapp.impl.security.auth.ContainerBasedAuthenticationFilter;
import org.springframework.boot.autoconfigure.security.SecurityProperties;
import org.springframework.boot.web.servlet.FilterRegistrationBean;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.annotation.Order;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.web.SecurityFilterChain;

import java.util.Collections;

@Configuration
@Order(SecurityProperties.BASIC_AUTH_ORDER - 15)
public class WebAppSecurityConfig {

    @Bean
    protected SecurityFilterChain configure(final HttpSecurity http) throws Exception {
        http.csrf(req -> req
                .ignoringRequestMatchers("/camunda/api/**"))
                .authorizeHttpRequests(req -> req
                        .requestMatchers("/**")
                        .authenticated()
                        .requestMatchers(
                                "/camunda/api/**",
                                "/camunda/app/*/styles/**",
                                "/camunda/assets/**",
                                "/camunda/favicon.ico",
                                "/camunda/lib/**")
                        .permitAll())
                .oauth2Login(req -> req
                        .defaultSuccessUrl("/camunda/app/welcome/default/#!/welcome"));
        return http.build();
    }

    @Bean
    public FilterRegistrationBean<?> containerBasedAuthenticationFilter() {
        final FilterRegistrationBean<ContainerBasedAuthenticationFilter> registry = new FilterRegistrationBean<>();
        registry.setName("camunda-cognito-container");
        registry.setFilter(new ContainerBasedAuthenticationFilter());
        registry.setInitParameters(Collections.singletonMap("authentication-provider",
                WebAppSecurityProvider.class.getName()));
        registry.setOrder(101);
        registry.addUrlPatterns("/*");
        return registry;
    }
}
