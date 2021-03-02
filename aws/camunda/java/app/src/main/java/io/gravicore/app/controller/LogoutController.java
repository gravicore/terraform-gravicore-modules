package io.gravicore.app.controller;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.web.DefaultRedirectStrategy;
import org.springframework.security.web.RedirectStrategy;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

@Controller
public class LogoutController {

    @Value("${spring.security.oauth2.client.provider.cognito.signout-uri}")
    private String signoutUri;
    @Value("${spring.security.oauth2.client.provider.cognito.sso.signout-uri}")
    private String ssoSignoutUri;
    private final RedirectStrategy redirectStrategy = new DefaultRedirectStrategy();

    @GetMapping("/logout/oauth2/code/custom")
    public void sendRedirect(final HttpServletRequest request,
                             final HttpServletResponse response) throws Exception {
        redirectStrategy.sendRedirect(request, response, signoutUri);
    }

    @GetMapping("/logout/oauth2/code/cognito")
    public void logout(final HttpServletRequest request,
                             final HttpServletResponse response) throws Exception {
        request.getSession().invalidate();
        redirectStrategy.sendRedirect(request, response, ssoSignoutUri);
    }

}
