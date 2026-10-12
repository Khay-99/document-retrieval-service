package io.blueeagle.docservice.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Target-group health check for blueeagle-prod-app-alb. Nothing more than a
 * liveness probe - it deliberately does not touch S3, so a bucket or
 * credentials problem never gets reported as an unhealthy instance.
 */
@RestController
public class HealthController {

    @GetMapping("/health")
    public String health() {
        return "OK";
    }
}
