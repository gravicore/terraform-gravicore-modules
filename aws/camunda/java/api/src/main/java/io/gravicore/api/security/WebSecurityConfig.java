package io.gravicore.api.security;

import io.gravicore.api.security.jwt.JwtRequestFilter;
import io.gravicore.api.security.jwt.JwtUnauthorized;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;

import org.springframework.security.config.Customizer;

@Configuration
@EnableWebSecurity
@EnableMethodSecurity(prePostEnabled = true)
public class WebSecurityConfig {

    private final JwtUnauthorized jwtUnauthorized;
    private final JwtRequestFilter jwtRequestFilter;

    @Autowired
    public WebSecurityConfig(final JwtUnauthorized jwtUnauthorized,
            final JwtRequestFilter jwtRequestFilter) {
        this.jwtUnauthorized = jwtUnauthorized;
        this.jwtRequestFilter = jwtRequestFilter;
    }

    @Bean
    protected SecurityFilterChain configure(final HttpSecurity http) throws Exception {
        http.cors(Customizer.withDefaults())
                .csrf(req -> req.disable())
                .authorizeHttpRequests(req -> req
                        .requestMatchers("/actuator/*").permitAll()
                        .anyRequest().authenticated())
                .exceptionHandling(req -> req.authenticationEntryPoint(jwtUnauthorized))
                .sessionManagement(req -> req.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .addFilterBefore(jwtRequestFilter, UsernamePasswordAuthenticationFilter.class);
        return http.build();
    }

}
