package compliance.hipaa.transmission.s3_tls_enforcement

import rego.v1

import data.compliance.lib

__rego_metadata__ := {
	"framework": "hipaa",
	"control_id": ["164.312(e)(1)"],
	"severity": "high",
	"description": "S3 uploads bucket must deny requests that do not use TLS.",
	"remediation": "Add aws_s3_bucket_policy with a Deny statement conditioned on aws:SecureTransport=false.",
}

deny contains msg if {
	not uploads_tls_deny_configured
	msg := "GAP-03: S3 uploads bucket policy must deny non-TLS access (aws:SecureTransport=false)."
}

bucket_policy_documents contains doc if {
	resource := lib.all_planned_resources[_]
	resource.type == "aws_s3_bucket_policy"
	is_string(resource.values.policy)
	doc := json.unmarshal(resource.values.policy)
}

uploads_tls_deny_configured if {
	some doc in bucket_policy_documents
	some stmt in doc.Statement
	stmt.Effect == "Deny"
	condition := object.get(stmt, "Condition", {})
	bool_cond := object.get(condition, "Bool", {})
	bool_cond["aws:SecureTransport"] == "false"
}
