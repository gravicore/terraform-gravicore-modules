package io.gravicore.api.security.jwt;

import com.auth0.jwk.Jwk;
import com.auth0.jwk.JwkProvider;
import com.auth0.jwk.UrlJwkProvider;
import com.auth0.jwt.JWT;
import com.auth0.jwt.algorithms.Algorithm;
import com.auth0.jwt.interfaces.DecodedJWT;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.security.interfaces.RSAPublicKey;
import java.util.Calendar;
import java.util.Date;

@Component
public class JwtValidator {

    private static final Logger LOGGER = LoggerFactory.getLogger(JwtValidator.class);

    @Value("${spring.security.jwk-uri}")
    private String jwkUri;

    public boolean validate(final String token) {
        try {
            final DecodedJWT jwt = JWT.decode(token);
            final JwkProvider provider = new UrlJwkProvider(jwkUri);
            final Jwk jwk = provider.get(jwt.getKeyId());
            final Algorithm algorithm = Algorithm.RSA256((RSAPublicKey)
                    jwk.getPublicKey(), null);
            this.verify(algorithm, jwt);
        } catch (final Exception e){
            LOGGER.error("Token unauthorized = {}", token, e);
            return false;
        }
        return true;
    }

    private void verify(final Algorithm algorithm, final DecodedJWT jwt) {
        algorithm.verify(jwt);
        final Date expiration = jwt.getExpiresAt();
        if (expiration.before(Calendar.getInstance().getTime())) {
            throw new IllegalArgumentException("Expired token");
        }
    }

}
