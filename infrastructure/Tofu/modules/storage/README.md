# Storage Module

Creates a private encrypted S3 bucket for DPN participant/application data.

This module does **not** grant workload access. IRSA or workload bucket policies should be added later when application access requirements are known.

DEV bucket:

```text
dpn-dev-627657103820-eu-west-2-data
```

Security baseline:

- S3 Block Public Access enabled
- Bucket owner enforced object ownership
- KMS server-side encryption
- Versioning enabled
- TLS-only bucket policy
- Incomplete multipart upload cleanup
- Noncurrent version lifecycle expiration
