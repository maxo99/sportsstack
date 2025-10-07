package com.maxo99.sportsstack.gateway.routes;

import java.net.URI;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.cloud.gateway.server.mvc.common.MvcUtils;
import org.springframework.cloud.gateway.server.mvc.filter.BeforeFilterFunctions;
import org.springframework.cloud.gateway.server.mvc.filter.CircuitBreakerFilterFunctions;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.client.RestTemplate;
import org.springframework.cloud.gateway.server.mvc.handler.GatewayRouterFunctions;
import org.springframework.cloud.gateway.server.mvc.handler.HandlerFunctions;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.function.RequestPredicates;
import org.springframework.web.servlet.function.RouterFunction;
import org.springframework.web.servlet.function.ServerResponse;

// Ref: https://docs.spring.io/spring-cloud-gateway/reference/spring-cloud-gateway-server-webmvc

@Configuration
public class Routes {

    @Value("${oddstracker.service.url}")
    private String oddstrackerServiceUrl;
    @Value("${rotoreader.service.url}")
    private String rotoreaderServiceUrl;

    @Bean
    public RouterFunction<ServerResponse> oddstrackerServiceRoute() {
        return GatewayRouterFunctions.route("simple_route").GET("/api/oddstracker/**", HandlerFunctions.http())
                .before(BeforeFilterFunctions.uri(oddstrackerServiceUrl))
                .before(BeforeFilterFunctions.stripPrefix(2))
                .filter(CircuitBreakerFilterFunctions.circuitBreaker("oddstrackerServiceCircuitBreaker",
                        URI.create("forward:/fallbackRoute")))
                .build();
    }

    @Bean
    public RouterFunction<ServerResponse> rotoreaderServiceRoute() {
        return GatewayRouterFunctions.route("simple_route").GET("/api/rotoreader/**", HandlerFunctions.http())
                .before(BeforeFilterFunctions.uri(rotoreaderServiceUrl))
                .before(BeforeFilterFunctions.stripPrefix(2))
                .filter(CircuitBreakerFilterFunctions.circuitBreaker("rotoreaderServiceCircuitBreaker",
                        URI.create("forward:/fallbackRoute")))
                .build();
    }

    @Bean
    public RouterFunction<ServerResponse> rotoreaderServiceSwaggerRoute() {
        return GatewayRouterFunctions.route("rotoreader_service_swagger")
                .GET("/aggregate/rotoreader/**", HandlerFunctions.http())
                .before(BeforeFilterFunctions.stripPrefix(2))
                .before(BeforeFilterFunctions.uri(rotoreaderServiceUrl))
                .build();
    }

    @Bean
    public RouterFunction<ServerResponse> oddstrackerServiceSwaggerRoute() {
        return GatewayRouterFunctions.route("oddstracker_service_swagger")
                .GET("/aggregate/oddstracker/**", HandlerFunctions.http())
                .before(BeforeFilterFunctions.stripPrefix(2))
                .before(BeforeFilterFunctions.uri(oddstrackerServiceUrl))
                .build();
    }

    @Bean
    public RouterFunction<ServerResponse> fallbackRoute() {
        return GatewayRouterFunctions.route("fallback_route")
                .route(RequestPredicates.path("/fallback"),
                        request -> ServerResponse.status(HttpStatus.SERVICE_UNAVAILABLE)
                                .body("Service is currently unavailable. Please try again later."))
                .build();
    }

}
