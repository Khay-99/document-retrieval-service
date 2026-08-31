package com.wandaprep.docservice.controller;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RestController;
import software.amazon.awssdk.core.ResponseBytes;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.GetObjectRequest;
import software.amazon.awssdk.services.s3.model.GetObjectResponse;
import software.amazon.awssdk.services.s3.model.NoSuchKeyException;
import software.amazon.awssdk.services.s3.model.S3Exception;

/**
 * This is the one endpoint the wider platform brief cares about: it must prove that the
 * application instance's IAM role - and only that role - can read objects from the
 * lifecycle-managed S3 bucket.
 *
 * GET /documents/{key} streams the object straight back to the caller. There is no local
 * caching and no public bucket access: every call goes through the SDK, using whatever
 * credentials DefaultCredentialsProvider resolves (the EC2 instance role, in production).
 */
@RestController
public class DocumentController {

    private final S3Client s3Client;

    @Value("${aws.s3.bucket}")
    private String bucketName;

    public DocumentController(S3Client s3Client) {
        this.s3Client = s3Client;
    }

    @GetMapping("/documents/{key}")
    public ResponseEntity<byte[]> getDocument(@PathVariable("key") String key) {
        try {
            GetObjectRequest request = GetObjectRequest.builder()
                    .bucket(bucketName)
                    .key(key)
                    .build();

            ResponseBytes<GetObjectResponse> objectBytes = s3Client.getObject(request, software.amazon.awssdk.core.sync.ResponseTransformer.toBytes());
            String contentType = objectBytes.response().contentType();

            return ResponseEntity.ok()
                    .contentType(contentType != null ? MediaType.parseMediaType(contentType) : MediaType.APPLICATION_OCTET_STREAM)
                    .header(HttpHeaders.CONTENT_DISPOSITION, "inline; filename=\"" + key + "\"")
                    .body(objectBytes.asByteArray());

        } catch (NoSuchKeyException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        } catch (S3Exception e) {
            // Deliberately not swallowed: a 403 here almost always means the instance role
            // policy is missing s3:GetObject, or the bucket policy is blocking this principal.
            return ResponseEntity.status(HttpStatus.BAD_GATEWAY)
                    .body(("S3 error: " + e.awsErrorDetails().errorMessage()).getBytes());
        }
    }
}
