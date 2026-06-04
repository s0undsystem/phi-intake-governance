package compliance.hipaa.encryption.s3_sse_kms

import rego.v1

import data.compliance.lib

__rego_metadata__ := {
	"framework": "hipaa",
	"control_id": ["164.312(a)(2)(iv)"],
	"severity": "high",
	"description": "S3 uploads bucket storing PHI attachments must use SSE-KMS with a customer-managed CMK.",
	"remediation": "Add aws_s3_bucket_server_side_encryption_configuration on the uploads bucket with sse_algorithm aws:kms and kms_master_key_id set to the PHI CMK.",
}

deny contains msg if {
	not uploads_sse_kms_configured
	msg := "GAP-01: S3 uploads bucket must use SSE-KMS with a customer-managed CMK (aws_s3_bucket_server_side_encryption_configuration with sse_algorithm aws:kms)."
}

uploads_sse_kms_configured if {
	some resource in lib.resources_by_type("aws_s3_bucket_server_side_encryption_configuration")
	some rule in object.get(resource.values, "rule", [])
	default_cfg := object.get(rule, "apply_server_side_encryption_by_default", [])
	count(default_cfg) > 0
	default_cfg[0].sse_algorithm == "aws:kms"
	default_cfg[0].kms_master_key_id != ""
}
