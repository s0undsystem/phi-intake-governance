# phi-intake-governance

Compliance-as-code wrapper around the Acme Health Patient Intake API. The underlying workload is a minimal AWS stack (VPC, Lambda, API Gateway, DynamoDB, S3) that ingests patient intake submissions over HTTPS. This repository adds GRC controls so the same workload is audit-defensible under the HIPAA Security Rule, with secondary crosswalks to SOC 2 TSC and CMMC L2 in OSCAL and [policies/crosswalk.md](policies/crosswalk.md).

## Architecture

1. **Terraform baseline** (`terraform/baseline/`) — CMK, SSE-KMS, CloudTrail, evidence vault (Object Lock), VPC endpoints, least-privilege IAM
2. **OPA policy suite** (`policies/`) — seven Rego policies; Conftest evaluates the Terraform plan JSON and fails closed on violation
3. **GitHub Actions pipeline** (`.github/workflows/compliance.yml`) — plan, Conftest gate, apply on merge, Cosign sign, upload to evidence vault, verify signature
4. **OSCAL component definition** (`oscal/`) — control implementations, Terraform resource props, framework crosswalk metadata

The starter workload is in `terraform/main.tf`. The baseline module wraps it without rewriting the application.

## Quick start

Requires `AWS_PROFILE` and remote state in `phi-intake-governance-tfstate`.

```bash
make deploy AWS_PROFILE=<your-profile>
make test
make conftest
```

Run `make creds` to confirm AWS identity. Run `make plan` before `make conftest` to generate `plan.json`. Tear down with `make destroy`.

## Compliance gaps

**Closed:** GAP-01 (S3 SSE-KMS), GAP-02 (DynamoDB CMK), GAP-03 (TLS bucket policy), GAP-04 (S3 versioning), GAP-05 (Lambda VPC), GAP-07 (least-privilege IAM), plus multi-region CloudTrail with log file validation. Each is enforced in Terraform and gated by a Rego policy.

**Deferred:** GAP-06 (Lambda concurrency, DLQ, X-Ray) and GAP-08 (API Gateway logging, throttling, WAF). See [GAPS.md](GAPS.md) for definitions.

Full design rationale, trade-offs, and framework crosswalk: [WRITEUP.md](WRITEUP.md).

## License

MIT
