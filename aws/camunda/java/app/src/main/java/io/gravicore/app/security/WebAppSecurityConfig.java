package io.gravicore.app.security;

import org.camunda.bpm.webapp.impl.security.auth.ContainerBasedAuthenticationFilter;
import org.springframework.boot.autoconfigure.security.SecurityProperties;
import org.springframework.boot.web.servlet.FilterRegistrationBean;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.annotation.Order;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.WebSecurityConfigurerAdapter;

import java.util.Collections;

@Configuration
@Order(SecurityProperties.BASIC_AUTH_ORDER - 15)
public class WebAppSecurityConfig extends WebSecurityConfigurerAdapter {

    @Override
    protected void configure(final HttpSecurity http) throws Exception {
        http
            .csrf().ignoringAntMatchers("/camunda/api/**")
            .and()
                .antMatcher("/**")
                .authorizeRequests()
                .antMatchers("/camunda/app/**")
                .authenticated()
                .antMatchers("/camunda/api/**")
                .permitAll()
                .antMatchers("/camunda/app/*/styles/*.css", "/camunda/app/*/styles/*.js")
                .permitAll()
            .and()
                .oauth2Login()
                .defaultSuccessUrl("/camunda/app/welcome/default/#!/welcome");
    }

    @Bean
    public FilterRegistrationBean<?> containerBasedAuthenticationFilter(){
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