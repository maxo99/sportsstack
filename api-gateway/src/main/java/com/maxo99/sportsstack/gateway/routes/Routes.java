package com.maxo99.sportsstack.gateway.routes;

import java.net.URI;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.cloud.gateway.server.mvc.filter.BeforeFilterFunctions;
import org.springframework.cloud.gateway.server.mvc.filter.CircuitBreakerFilterFunctions;
import org.springframework.http.HttpStatus;
import org.springframework.cloud.gateway.server.mvc.handler.GatewayRouterFunctions;
import org.springframework.cloud.gateway.server.mvc.handler.HandlerFunctions;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.function.HandlerFilterFunction;
import org.springframework.web.servlet.function.RequestPredicates;
import org.springframework.web.servlet.function.RouterFunction;
import org.springframework.web.servlet.function.ServerResponse;

// Ref: https://docs.spring.io/spring-cloud-gateway/reference/spring-cloud-gateway-server-webmvc

@Configuration
public class Routes {

        private static final org.slf4j.Logger log = org.slf4j.LoggerFactory.getLogger(Routes.class);

        @Value("${oddstracker.service.url}")
        private String oddstrackerServiceUrl;
        @Value("${rotoreader.service.url}")
        private String rotoreaderServiceUrl;
        @Value("${gosportsagent.service.url}")
        private String gosportsagentServiceUrl;

        private HandlerFilterFunction<ServerResponse, ServerResponse> logRequest() {
                return (request, next) -> {
                        log.info("Incoming request: {} {} from {}",
                                        request.method(),
                                        request.uri().getPath(),
                                        request.remoteAddress().orElse(null));
                        return next.handle(request);
                };
        }

        @Bean
        public RouterFunction<ServerResponse> oddstrackerServiceRoute() {
                return GatewayRouterFunctions.route("oddstracker_service_route")
                                .route(RequestPredicates.path("/api/oddstracker/**"),
                                                HandlerFunctions.http(oddstrackerServiceUrl))
                                .before(BeforeFilterFunctions.stripPrefix(2))
                                .filter(logRequest())
                                .filter(CircuitBreakerFilterFunctions.circuitBreaker("oddstrackerServiceCircuitBreaker",
                                                URI.create("forward:/fallbackRoute")))
                                .build();
        }

        @Bean
        public RouterFunction<ServerResponse> rotoreaderServiceRoute() {
                return GatewayRouterFunctions.route("rotoreader_service_route")
                                .route(RequestPredicates.path("/api/rotoreader/**"),
                                                HandlerFunctions.http(rotoreaderServiceUrl))
                                .before(BeforeFilterFunctions.stripPrefix(2))
                                .filter(logRequest())
                                .filter(CircuitBreakerFilterFunctions.circuitBreaker("rotoreaderServiceCircuitBreaker",
                                                URI.create("forward:/fallbackRoute")))
                                .build();
        }

        @Bean
        public RouterFunction<ServerResponse> gosportsagentServiceRoute() {
                log.info("Configuring gosportsagent route with URL: {}", gosportsagentServiceUrl);
                return GatewayRouterFunctions.route("gosportsagent_service_route")
                                .route(RequestPredicates.path("/api/gosportsagent/**"),
                                                HandlerFunctions.http(gosportsagentServiceUrl))
                                .before(BeforeFilterFunctions.stripPrefix(2))
                                .filter(logRequest())
                                .filter(CircuitBreakerFilterFunctions.circuitBreaker(
                                                "gosportsagentServiceCircuitBreaker",
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
