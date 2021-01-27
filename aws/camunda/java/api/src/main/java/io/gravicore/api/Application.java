package io.gravicore.api;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;

import com.timgroup.statsd.NonBlockingStatsDClientBuilder;
import com.timgroup.statsd.StatsDClient;

@SpringBootApplication
public class Application {

    @Value("${dd.agent.host}")
    private String statsdHost;
    @Value("${dd.statsd.agent.prefix}")
    private String statsdPrefix;
    @Value("${dd.statsd.agent.port}")
    private Integer statsdPort;

    public static void main(String... args) {
        SpringApplication.run(Application.class, args);
    }

    @Bean
    public StatsDClient statsDClient() {
        return new NonBlockingStatsDClientBuilder()
                .prefix(statsdPrefix)
                .hostname(statsdHost)
                .port(statsdPort)
            .build();
    } 

}