# Framework Crosswalk — Patient Intake API Policy Suite

This document maps each Rego policy in the Patient Intake API compliance suite to its primary HIPAA Security Rule control and secondary crosswalks under SOC 2 Trust Services Criteria and CMMC Level 2. The design follows a **build-once, point-many** philosophy: each technical control is implemented once in Terraform, validated once by a Rego policy, and evidenced once by the CI pipeline. Auditors reviewing HIPAA, SOC 2, or CMMC can cite the same artifact—a signed bundle in the S3 evidence vault—without requiring separate enforcement stacks per framework. One evidence pipeline (plan → Conftest → apply → Cosign sign → upload → verify) satisfies multiple frameworks simultaneously because the underlying safeguards (encryption, least privilege, audit logging) are framework-agnostic; only the control narrative changes.

## Control mapping

| Policy | Primary HIPAA (164.x) | SOC 2 TSC | CMMC L2 | Gap | Rationale |
|---|---|---|---|---|---|
| `s3_sse_kms.rego` | 164.312(a)(2)(iv) | CC6.1 | SC.L2-3.13.11 | GAP-01 | SSE-KMS with a customer-managed CMK places PHI encryption keys under customer custody, satisfying HIPAA encryption addressable implementation, SOC 2 logical access to cryptographic assets, and CMMC confidentiality protection for stored data—all via one S3 encryption configuration. |
| `dynamodb_cmk.rego` | 164.312(a)(2)(iv) | CC6.1 | SC.L2-3.13.11 | GAP-02 | DynamoDB server-side encryption with a CMK extends the same at-rest protection to submission records; the crosswalk is identical to S3 because all three frameworks require customer-controlled encryption for sensitive data at rest. |
| `s3_tls_enforcement.rego` | 164.312(e)(1) | CC6.7 | SC.L2-3.13.8 | GAP-03 | A bucket policy denying `aws:SecureTransport=false` enforces TLS for every S3 API call, directly addressing HIPAA transmission security and mapping to SOC 2 CC6.7 and CMMC encryption-in-transit requirements with a single deny statement. |
| `s3_versioning.rego` | 164.308(a)(7) | A1.2 | MP.L2-3.8.9 | GAP-04 | Versioning enables recovery from accidental PHI overwrites, supporting HIPAA contingency planning, SOC 2 availability/recoverability (A1.2), and CMMC media protection backup practices through one bucket setting. |
| `lambda_vpc.rego` | 164.312(e)(1) | CC6.6 | SC.L2-3.13.1 | GAP-05 | Placing Lambda in private subnets with security groups implements network boundary protection required by HIPAA transmission/boundary safeguards, SOC 2 CC6.6, and CMMC SC.L2-3.13.1 without separate network controls per framework. |
| `iam_least_privilege.rego` | 164.312(a)(1) | CC6.3 | AC.L2-3.1.5 | GAP-07 | Scoped IAM actions (`PutItem`, `PutObject`, required KMS grants) replace wildcard `dynamodb:*` and `s3:*`, satisfying HIPAA access control, SOC 2 authorization (CC6.3), and CMMC least privilege (AC.L2-3.1.5) in one inline policy. |
| `cloudtrail_audit.rego` | 164.312(b) | CC7.2 | AU.L2-3.3.1 | — | Multi-region CloudTrail with log file validation generates tamper-evident audit records for HIPAA audit controls, SOC 2 monitoring (CC7.2), and CMMC audit record generation (AU.L2-3.3.1). |

## Evidence linkage

All policies gate merges through the GitHub Actions workflow at [`.github/workflows/compliance.yml`](../.github/workflows/compliance.yml). On every push to `main`, the pipeline produces a signed evidence bundle and uploads it to the S3 evidence vault (`module.grc_baseline.aws_s3_bucket.evidence`). OSCAL `evidence-uri` props in [`oscal/component-definition.json`](../oscal/component-definition.json) reference this vault prefix. Auditors tracing any control in this table should start at the bundle for the relevant git commit SHA under `s3://<evidence-bucket>/evidence/<git-sha>/`.

## Namespace convention

All policies use the `compliance.hipaa.*` package hierarchy configured in [`conftest.toml`](../conftest.toml). Primary framework attribution is always HIPAA; SOC 2 and CMMC mappings appear here and in OSCAL props as secondary crosswalks.
