package com.maxo99.sportsstack.gateway.routes;

import java.net.URI;

import org.springframework.cloud.gateway.server.mvc.common.MvcUtils;
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


@Configuration
public class Routes {

    // @Value("${product.service.url}")
    // private String productServiceUrl;
    // @Value("${order.service.url}")
    // private String orderServiceUrl;
    // @Value("${inventory.service.url}")
    // private String inventoryServiceUrl;

    private ServerResponse proxyTo(String url) {
        RestTemplate restTemplate = new RestTemplate();
        ResponseEntity<String> response = restTemplate.getForEntity(url, String.class);
        return ServerResponse.status(response.getStatusCode()).body(response.getBody());
    }

    @Bean
    public RouterFunction<ServerResponse> productServiceRoute() {
        return GatewayRouterFunctions.route("product_service")
                .route(RequestPredicates.path("/api/product"), request -> {
                    MvcUtils.setRequestUrl(request, URI.create("http://localhost:8080"));
                    return HandlerFunctions.http().handle(request);
                })
                .filter(CircuitBreakerFilterFunctions.circuitBreaker("productServiceCircuitBreaker",
                        URI.create("forward:/fallbackRoute")))
                .build();
    }

    @Bean
    public RouterFunction<ServerResponse> orderServiceRoute() {
        return GatewayRouterFunctions.route("order_service")
                .route(RequestPredicates.path("/api/order"), request -> {
                    MvcUtils.setRequestUrl(request, URI.create("http://localhost:8081"));
                    return HandlerFunctions.http().handle(request);
                })
                .filter(CircuitBreakerFilterFunctions.circuitBreaker("orderServiceCircuitBreaker",
                        URI.create("forward:/fallbackRoute")))
                .build();
    }

    @Bean
    public RouterFunction<ServerResponse> inventoryServiceRoute() {
        return GatewayRouterFunctions.route("inventory_service")
                .route(RequestPredicates.path("/api/inventory"), request -> {
                    MvcUtils.setRequestUrl(request, URI.create("http://localhost:8082"));
                    return HandlerFunctions.http().handle(request);
                })
                .filter(CircuitBreakerFilterFunctions.circuitBreaker("inventoryServiceCircuitBreaker",
                        URI.create("forward:/fallbackRoute")))
                .build();
    }

    @Bean
    public RouterFunction<ServerResponse> productServiceSwaggerRoute() {
        return GatewayRouterFunctions.route("product_service_swagger")
                .route(RequestPredicates.path("/aggregate/product/**"), request -> {
                    String path = request.path();
                    String backendPath = path.replace("/aggregate/product", "");
                    return proxyTo("http://localhost:8080" + backendPath);
                })
                .build();
    }

    @Bean
    public RouterFunction<ServerResponse> orderServiceSwaggerRoute() {
        return GatewayRouterFunctions.route("order_service_swagger")
                .route(RequestPredicates.path("/aggregate/order/**"), request -> {
                    String path = request.path();
                    String backendPath = path.replace("/aggregate/order", "");
                    return proxyTo("http://localhost:8081" + backendPath);
                })
                .build();
    }

    @Bean
    public RouterFunction<ServerResponse> inventoryServiceSwaggerRoute() {
        return GatewayRouterFunctions.route("inventory_service_swagger")
                .route(RequestPredicates.path("/aggregate/inventory/**"), request -> {
                    String path = request.path();
                    String backendPath = path.replace("/aggregate/inventory", "");
                    return proxyTo("http://localhost:8082" + backendPath);
                })
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
