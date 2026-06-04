package compliance.hipaa.encryption.dynamodb_cmk

import rego.v1

import data.compliance.lib

__rego_metadata__ := {
	"framework": "hipaa",
	"control_id": ["164.312(a)(2)(iv)"],
	"severity": "high",
	"description": "DynamoDB submissions table must encrypt PHI at rest with a customer-managed CMK.",
	"remediation": "Add server_side_encryption block on aws_dynamodb_table.intake with enabled=true and kms_key_arn referencing the PHI CMK.",
}

deny contains msg if {
	not intake_table_cmk_configured
	msg := "GAP-02: DynamoDB intake table must use a customer-managed KMS key (server_side_encryption.kms_key_arn)."
}

intake_table_cmk_configured if {
	some resource in lib.resources_by_type("aws_dynamodb_table")
	resource.name == "intake"
	sse := object.get(resource.values, "server_side_encryption", [])
	sse != []
	sse[0].enabled == true
	sse[0].kms_key_arn != ""
}
