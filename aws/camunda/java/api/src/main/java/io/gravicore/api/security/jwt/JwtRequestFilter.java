package io.gravicore.api.security.jwt;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContext;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import javax.servlet.FilterChain;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.Collections;
import java.util.Optional;

import static org.apache.commons.lang3.StringUtils.EMPTY;
import static org.apache.commons.lang3.StringUtils.isNotBlank;

@Component
public class JwtRequestFilter extends OncePerRequestFilter {

    private static final Logger LOGGER = LoggerFactory.getLogger(JwtRequestFilter.class);
    private static final String AUTHORIZATION = "authorization";
    private static final String DEFAULT_ROLE = "ROLE_ADMIN";
    private final JwtValidator validator;

    @Autowired
    public JwtRequestFilter(final JwtValidator validator) {
        this.validator = validator;
    }

    @Override
    protected void doFilterInternal(final HttpServletRequest request,
                                    final HttpServletResponse response,
                                    final FilterChain chain) throws IOException, ServletException {
        final String token = this.getJsonWebToken(request);
        final SecurityContext context = SecurityContextHolder.getContext();
        if (isNotBlank(token) && context.getAuthentication() == null) {
            if (this.validator.validate(token)) {
                final UsernamePasswordAuthenticationToken authentication = new UsernamePasswordAuthenticationToken(token, null,
                        Collections.singletonList(new SimpleGrantedAuthority(DEFAULT_ROLE)));
                authentication.setDetails(new WebAuthenticationDetailsSource().buildDetails(request));
                LOGGER.info("Authenticated token = {}", token);
                context.setAuthentication(authentication);
            }
        }
        chain.doFilter(request, response);
    }

    private String getJsonWebToken(final HttpServletRequest request) {
        return Optional.ofNullable(request.getHeader(AUTHORIZATION)).orElse(EMPTY);
    }

}