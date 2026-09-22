package io.blueeagle.docservice.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import software.amazon.awssdk.auth.credentials.DefaultCredentialsProvider;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.s3.S3Client;

/**
 * Builds the shared S3Client bean used by every controller that talks to the
 * document bucket.
 *
 * Credentials are NEVER hardcoded. DefaultCredentialsProvider resolves, in
 * order: environment variables, a local AWS CLI profile (useful when running
 * this service on your own machine against a dev bucket), and finally the
 * EC2 instance profile attached to blueeagle-prod-app-lt when this runs on
 * the Auto Scaling Group in AWS. In production that instance-role path is
 * the only one that ever fires - there is no access key anywhere in this
 * repo or in the deployed environment.
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
