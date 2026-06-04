# Patient Intake API — GRC Capstone Write-up

## Design Decisions

This submission treats the HIPAA Security Rule as the primary compliance framework because the workload's core risk is PHI. The Patient Intake API accepts patient identifiers, visit reason, pharmacy NPI, and optional attachment content over HTTPS. That data classification makes HIPAA the natural anchor regardless of whether Acme Health is also pursuing SOC 2 customer attestations or CMMC for federal pilots. NIST SP 800-66 Rev. 2 is cited as the OSCAL catalog source because NIST publishes implementation guidance for the Security Rule in a form assessors can trace, even though HIPAA itself has no official OSCAL catalog.

The Terraform layout uses a baseline child module at `terraform/baseline/` rather than a flat single root because GRC concerns are separable from workload concerns. The starter workload in `terraform/main.tf` remains the application team's surface area: VPC, Lambda, API Gateway, DynamoDB, S3. The baseline module owns the controls an inherited system would need wrapped around it: CMK, evidence vault, CloudTrail, VPC endpoints, NAT, and least-privilege IAM. That separation makes the baseline a reusable primitive. A different workload in the same account could call the same module with its own bucket and table ARNs without copying KMS or trail boilerplate.

Object Lock on the evidence vault uses GOVERNANCE mode with a 365-day default retention rather than COMPLIANCE mode. This is a sandbox decision. GOVERNANCE allows privileged users to override retention when needed for debugging or re-deploy cycles, which matters during capstone iteration. In production I would move to COMPLIANCE mode after a legal hold review process is documented, because COMPLIANCE retention cannot be shortened by anyone including the root account without a support ticket, which is the stronger chain-of-custody posture for PHI-adjacent audit artifacts.

Network egress for the VPC-attached Lambda uses gateway endpoints for S3 and DynamoDB plus an interface endpoint for CloudWatch Logs, with a single NAT gateway for residual HTTPS. A VPC-only design without NAT failed in practice: Lambda timed out because gateway endpoints route via prefix lists in the route table, not via addresses inside the VPC CIDR, and the original security group egress rule scoped to `10.42.0.0/16` blocked that traffic. Gateway endpoints keep S3 and DynamoDB traffic off the NAT and reduce cost for the hot path. NAT remains for anything that still needs outbound HTTPS. For a low-traffic intake API in a sandbox, one NAT is an acceptable recurring cost.

Cryptography uses a single customer-managed KMS key (`module.grc_baseline.aws_kms_key.phi`) with rotation enabled rather than per-service keys. Acme Health at roughly 50 people does not need the operational overhead of separate keys for uploads, DynamoDB, CloudTrail, and the evidence vault when a single key policy can scope service principals by `kms:ViaService` and caller account. The custody story is simpler for assessors: one CMK, one rotation schedule, one key policy document. Per-service keys would be appropriate if different teams owned different data classes or if a key compromise needed blast-radius isolation beyond what IAM already provides.

Evidence signing uses Cosign keyless signing via GitHub OIDC rather than GPG. There is no long-lived signing secret stored in the repository or in a CI secret manager. The signature identity is bound to the workflow run and repository context. Sigstore's transparency log provides an independent audit trail of signing events outside AWS, which complements CloudTrail's record of what happened inside the account. The pipeline uploads `bundle.tar.gz` and `bundle.tar.gz.bundle` to the evidence vault and verifies the signature in-band before the job completes.

## Control Coverage

Each closed gap is enforced in Terraform and gated in CI by a Rego policy that evaluates the Terraform plan JSON. CloudTrail has no named starter gap but implements HIPAA 164.312(b) and is policy-gated the same way.

| Rego policy | Gap | HIPAA control | Terraform remediation | Enforcement |
|---|---|---|---|---|
| `policies/s3_sse_kms.rego` | GAP-01 | 164.312(a)(2)(iv) | `module.grc_baseline.aws_s3_bucket_server_side_encryption_configuration.uploads` (SSE-KMS with `module.grc_baseline.aws_kms_key.phi`) | Terraform + policy |
| `policies/dynamodb_cmk.rego` | GAP-02 | 164.312(a)(2)(iv) | `aws_dynamodb_table.intake` (`server_side_encryption.kms_key_arn = module.grc_baseline.kms_key_arn`) | Terraform + policy |
| `policies/s3_tls_enforcement.rego` | GAP-03 | 164.312(e)(1) | `module.grc_baseline.aws_s3_bucket_policy.uploads` (`aws:SecureTransport` deny) | Terraform + policy |
| `policies/s3_versioning.rego` | GAP-04 | 164.308(a)(7) | `module.grc_baseline.aws_s3_bucket_versioning.uploads` | Terraform + policy |
| `policies/lambda_vpc.rego` | GAP-05 | 164.312(e)(1) | `aws_lambda_function.intake` (`vpc_config` referencing `aws_subnet.private[*]` and `module.grc_baseline.aws_security_group.lambda`) | Terraform + policy |
| `policies/iam_least_privilege.rego` | GAP-07 | 164.312(a)(1) | `module.grc_baseline.aws_iam_role_policy.lambda_data_access` (replaces starter `aws_iam_role_policy.lambda_inline`) | Terraform + policy |
| `policies/cloudtrail_audit.rego` | (audit baseline) | 164.312(b) | `module.grc_baseline.aws_cloudtrail.phi` (`is_multi_region_trail`, `enable_log_file_validation`) | Terraform + policy |

Supporting resources not individually gated by policy but part of the control implementation include `module.grc_baseline.aws_kms_key.phi`, `module.grc_baseline.aws_s3_bucket.evidence` (Object Lock GOVERNANCE, 365 days), `module.grc_baseline.aws_vpc_endpoint.s3`, `module.grc_baseline.aws_vpc_endpoint.dynamodb`, and `module.grc_baseline.aws_vpc_endpoint.logs`. The starter resource `aws_s3_bucket.uploads` and `aws_iam_role.lambda` remain in the root module; the baseline module attaches sidecar resources and policies to them by reference.

The policy suite can be validated locally with `make plan && make conftest`. Unit tests in `policies/*_test.rego` confirm each policy passes on a compliant plan fixture and fails on a starter-gap fixture.

## Framework Crosswalk

The build-once-point-many thesis is that a well-designed evidence pipeline is framework-agnostic at the artifact layer. Terraform implements a control once. Conftest verifies it once against the plan. Cosign signs the resulting evidence bundle once. That single signed artifact under `s3://<evidence-bucket>/evidence/<git-sha>/` can satisfy HIPAA audit control evidence, SOC 2 monitoring criteria, and CMMC audit record requirements without maintaining three separate pipelines. The frameworks differ in how assessors narrate the control, not in the underlying technical facts: the bucket was encrypted with a CMK, the IAM policy was least-privilege, CloudTrail was multi-region with log file validation enabled.

Secondary framework mappings live in OSCAL props on each `implemented-requirement` in [`oscal/component-definition.json`](oscal/component-definition.json) and in [`policies/crosswalk.md`](policies/crosswalk.md). The component definition is the single source of truth for crosswalk metadata; Rego policies carry HIPAA as the primary framework per capstone rules.

| HIPAA (164.x) | SOC 2 TSC | CMMC L2 | Primary Terraform / policy anchor |
|---|---|---|---|
| 164.312(a)(2)(iv) | CC6.1 | SC.L2-3.13.11 | CMK + SSE on S3 uploads and DynamoDB (`s3_sse_kms.rego`, `dynamodb_cmk.rego`) |
| 164.312(a)(1) | CC6.3 | AC.L2-3.1.5 | `module.grc_baseline.aws_iam_role_policy.lambda_data_access` (`iam_least_privilege.rego`) |
| 164.312(e)(1) transmission | CC6.7 | SC.L2-3.13.8 | `module.grc_baseline.aws_s3_bucket_policy.uploads` (`s3_tls_enforcement.rego`) |
| 164.312(e)(1) boundary | CC6.6 | SC.L2-3.13.1 | Lambda VPC + SG + endpoints (`lambda_vpc.rego`) |
| 164.308(a)(7) | A1.2 | MP.L2-3.8.9 | `module.grc_baseline.aws_s3_bucket_versioning.uploads` (`s3_versioning.rego`) |
| 164.312(b) | CC7.2 | AU.L2-3.3.1 | `module.grc_baseline.aws_cloudtrail.phi` (`cloudtrail_audit.rego`) |

## Trade-offs

Sandbox deployment uses root-equivalent credentials via a personal AWS profile for local `make deploy`, and the GitHub Actions workflow assumes an OIDC role configured with broad permissions to unblock capstone iteration. In production I would replace local root usage with a scoped IAM role limited to the Terraform state bucket, the baseline module resources, and read-only plan permissions for CI. The OIDC role would be narrowed from AdministratorAccess to explicit `terraform`-required actions per resource type, with separation between plan-only PR jobs and apply-on-merge jobs.

The CloudTrail KMS key policy statement `AllowCloudTrailViaService` currently has no encryption context condition. Tighter conditions on `kms:EncryptionContext:aws:cloudtrail:arn` failed with `InsufficientEncryptionPolicyException` during trail creation in this sandbox, including when using root credentials. The working statement grants CloudTrail the minimum KMS actions without conditions so the trail could be created and validated. In production I would create the trail first under the permissive statement, then tighten the key policy with encryption context and trail ARN scoping once the trail resource exists and AWS validation accepts the condition set.

The Lambda security group egress rule allows TCP 443 to `0.0.0.0/0`. This is standard for architectures that rely on gateway endpoints, because the security group cannot enumerate the AWS-managed prefix lists those endpoints use. Actual traffic destination is controlled by the private route table: S3 and DynamoDB prefix lists route to gateway endpoints, and the default route sends remaining HTTPS to NAT. For production I would add network ACL egress restrictions on the private subnets as a defense-in-depth layer behind the security group.

GAP-06 and GAP-08 are intentionally deferred. They are observability and edge-hardening controls, not data-at-rest or data-in-transit protections. Closing them is planned for the next sprint and documented in OSCAL and this write-up rather than addressed with partial controls that would not survive scrutiny.

## Next Sprint

GAP-06 targets Lambda observability: reserved concurrency to cap blast radius under load, a dead-letter queue for failed invocations, and X-Ray tracing for request-level visibility. These map to SOC 2 CC7.2 and CMMC SI.L2-3.14.6. Implementation would extend `aws_lambda_function.intake` in the root module and add supporting SQS and IAM resources in the baseline module.

GAP-08 targets API Gateway hardening on `aws_apigatewayv2_stage.default`: access logging to CloudWatch, stage-level throttling, and WAF association. These address HIPAA 164.312(b) at the application edge and complement CloudTrail's account-level audit record. CloudTrail alone does not capture request payloads or WAF block events.

KMS hardening would reintroduce encryption context conditions on the CloudTrail and S3 statements after the trail is stable. Network ACLs would restrict private subnet egress beyond the current security group. The evidence vault would move to a separate AWS account for stronger chain-of-custody separation between the workload operator and the evidence custodian. Object Lock would transition from GOVERNANCE to COMPLIANCE mode once a legal hold review process is written and approved.

## Known Gaps

GAP-06 (Lambda observability) and GAP-08 (API Gateway hardening) are not closed in this submission. GAP-06 leaves `aws_lambda_function.intake` without reserved concurrency, without a DLQ, and without X-Ray. Relevant crosswalk criteria include SOC 2 CC7.2 and CMMC SI.L2-3.14.6. GAP-08 leaves `aws_apigatewayv2_stage.default` without access logging, throttling limits, or WAF. Relevant criteria include HIPAA 164.312(b), SOC 2 CC7.2, and CMMC AU.L2-3.3.1.

Both gaps are operational and observability controls rather than data protection controls. The PHI protection surface addressed in this submission is encryption at rest via CMK on S3 and DynamoDB, encryption in transit via TLS-enforcing bucket policies, access control via least-privilege IAM, network boundary via VPC-attached Lambda, contingency support via S3 versioning, and audit logging via multi-region CloudTrail with log file validation. An honest documented gap with a concrete remediation plan is preferable to a weak partial control that an assessor would reject on inspection. The Rego policy suite and OSCAL component do not claim coverage for GAP-06 or GAP-08.
