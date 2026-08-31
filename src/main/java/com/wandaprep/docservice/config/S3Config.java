package com.wandaprep.docservice.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import software.amazon.awssdk.auth.credentials.DefaultCredentialsProvider;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.s3.S3Client;

/**
 * Builds a single S3Client bean for the whole application.
 *
 * DefaultCredentialsProvider is deliberate: on a developer laptop it falls back to your local
 * AWS CLI profile; on EC2 it automatically picks up the IAM role attached to the instance via
 * the instance metadata service. No access keys should ever be set as environment variables
 * or config values in this project.
 */
@Configuration
public class S3Config {

    @Value("${aws.region}")
    private String region;

    @Bean
    public S3Client s3Client() {
        return S3Client.builder()
                .region(Region.of(region))
                .credentialsProvider(DefaultCredentialsProvider.create())
                .build();
    }
}
