package io.gravicore.api.security;

import io.gravicore.api.security.jwt.JwtRequestFilter;
import io.gravicore.api.security.jwt.JwtUnauthorized;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.method.configuration.EnableGlobalMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configuration.WebSecurityConfigurerAdapter;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;

@Configuration
@EnableWebSecurity
@EnableGlobalMethodSecurity(prePostEnabled = true)
public class WebSecurityConfig extends WebSecurityConfigurerAdapter {

    private final JwtUnauthorized jwtUnauthorized;
    private final JwtRequestFilter jwtRequestFilter;

    @Autowired
    public WebSecurityConfig(final JwtUnauthorized jwtUnauthorized,
                             final JwtRequestFilter jwtRequestFilter) {
        this.jwtUnauthorized = jwtUnauthorized;
        this.jwtRequestFilter = jwtRequestFilter;
    }

    @Override
    protected void configure(final HttpSecurity http) throws Exception {
        http.cors().and().csrf().disable()
            .authorizeRequests()
                .antMatchers("/actuator/*")
                .permitAll()
                .anyRequest()
                .authenticated()
            .and()
                .exceptionHandling()
                .authenticationEntryPoint(jwtUnauthorized)
            .and()
                .sessionManagement()
                .sessionCreationPolicy(SessionCreationPolicy.STATELESS)
            .and()
                .addFilterBefore(jwtRequestFilter, UsernamePasswordAuthenticationFilter.class);
    }

}