package io.blueeagle.docservice.controller;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import software.amazon.awssdk.core.ResponseBytes;
import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.*;

import java.io.IOException;
import java.time.Instant;
import java.util.List;
import java.util.stream.Collectors;

/**
 * BlueEagle KYC document API.
 *
 * A document belongs to a client reference (the KYC case/customer ID) and is
 * stored in S3 under the key "{clientRef}/{filename}". That prefix is the
 * whole model: there is no database here, no document table - S3 itself,
 * keyed by prefix, is the system of record for "what has this client given
 * us". The landing page under /index.html is a thin UI over these three
 * endpoints.
 *
 * IAM note: the instance role this controller runs under
 * (blueeagle-prod-app-role, see policies/step0-platform-engineer-iam-policy.json
 * in the security-automation repo for the equivalent least-privilege
 * pattern) is scoped to s3:GetObject, s3:PutObject and s3:ListBucket on the
 * one blueeagle-prod-documents bucket only - never s3:*, never another
 * bucket.
 */
@RestController
@RequestMapping("/api/documents")
public class DocumentController {

    private final S3Client s3Client;

    @Value("${aws.s3.bucket}")
    private String bucketName;

    public DocumentController(S3Client s3Client) {
        this.s3Client = s3Client;
    }

    /**
     * Upload (or overwrite) a single document for a client reference.
     * multipart/form-data, field name "file".
     */
    @PutMapping("/{clientRef}/{filename}")
    public ResponseEntity<?> uploadDocument(
            @PathVariable("clientRef") String clientRef,
            @PathVariable("filename") String filename,
            @RequestParam("file") MultipartFile file) {

        if (file.isEmpty()) {
            return ResponseEntity.badRequest().body("Uploaded file is empty.");
        }

        String key = buildKey(clientRef, filename);

        try {
            PutObjectRequest putRequest = PutObjectRequest.builder()
                    .bucket(bucketName)
                    .key(key)
                    .contentType(resolveContentType(file))
                    .metadata(java.util.Map.of(
                            "uploaded-by", "kyc-portal",
                            "client-ref", clientRef
                    ))
                    .build();

            s3Client.putObject(putRequest, RequestBody.fromInputStream(file.getInputStream(), file.getSize()));

            return ResponseEntity.status(HttpStatus.CREATED).body(new UploadResult(key, file.getSize()));
        } catch (IOException e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body("Could not read the uploaded file: " + e.getMessage());
        } catch (S3Exception e) {
            return ResponseEntity.status(HttpStatus.BAD_GATEWAY)
                    .body("S3 error while storing document: " + e.awsErrorDetails().errorMessage());
        }
    }

    /**
     * Retrieve a single document by client reference and filename.
     */
    @GetMapping("/{clientRef}/{filename}")
    public ResponseEntity<byte[]> getDocument(
            @PathVariable("clientRef") String clientRef,
            @PathVariable("filename") String filename) {

        String key = buildKey(clientRef, filename);

        try {
            GetObjectRequest request = GetObjectRequest.builder()
                    .bucket(bucketName)
                    .key(key)
                    .build();

            ResponseBytes<GetObjectResponse> objectBytes = s3Client.getObject(request, software.amazon.awssdk.core.sync.ResponseTransformer.toBytes());
            String contentType = objectBytes.response().contentType();

            return ResponseEntity.ok()
                    .contentType(contentType != null ? MediaType.parseMediaType(contentType) : MediaType.APPLICATION_OCTET_STREAM)
                    .header(HttpHeaders.CONTENT_DISPOSITION, "inline; filename=\"" + filename + "\"")
                    .body(objectBytes.asByteArray());
        } catch (NoSuchKeyException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        } catch (S3Exception e) {
            return ResponseEntity.status(HttpStatus.BAD_GATEWAY)
                    .body(("S3 error: " + e.awsErrorDetails().errorMessage()).getBytes());
        }
    }

    /**
     * List every document on file for a client reference - what the
     * portal's "My Documents" panel calls to render the table.
     */
    @GetMapping("/{clientRef}")
    public ResponseEntity<?> listDocuments(@PathVariable("clientRef") String clientRef) {
        String prefix = clientRef + "/";

        try {
            ListObjectsV2Request request = ListObjectsV2Request.builder()
                    .bucket(bucketName)
                    .prefix(prefix)
                    .build();

            List<DocumentSummary> documents = s3Client.listObjectsV2(request).contents().stream()
                    .map(obj -> new DocumentSummary(
                            obj.key().substring(prefix.length()),
                            obj.size(),
                            obj.lastModified()))
                    .collect(Collectors.toList());

            return ResponseEntity.ok(documents);
        } catch (S3Exception e) {
            return ResponseEntity.status(HttpStatus.BAD_GATEWAY)
                    .body("S3 error while listing documents: " + e.awsErrorDetails().errorMessage());
        }
    }

    private String buildKey(String clientRef, String filename) {
        return clientRef + "/" + filename;
    }

    private String resolveContentType(MultipartFile file) {
        String contentType = file.getContentType();
        return contentType != null ? contentType : "application/octet-stream";
    }

    /** Response body for a successful upload. */
    record UploadResult(String key, long sizeBytes) {
    }

    /** One row in a client's document listing. */
    record DocumentSummary(String filename, long sizeBytes, Instant lastModified) {
    }
}
