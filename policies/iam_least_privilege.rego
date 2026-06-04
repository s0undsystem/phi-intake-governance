package compliance.hipaa.access.iam_least_privilege

import rego.v1

import data.compliance.lib

__rego_metadata__ := {
	"framework": "hipaa",
	"control_id": ["164.312(a)(1)"],
	"severity": "critical",
	"description": "Lambda IAM role must use least-privilege actions on DynamoDB and S3, not wildcard grants.",
	"remediation": "Replace dynamodb:* and s3:* with scoped actions: dynamodb:PutItem, dynamodb:DescribeTable, s3:PutObject, and required KMS actions.",
}

deny contains msg if {
	lib.policy_actions["dynamodb:*"]
	msg := "GAP-07: Lambda IAM policy must not include dynamodb:*."
}

deny contains msg if {
	lib.policy_actions["s3:*"]
	msg := "GAP-07: Lambda IAM policy must not include s3:*."
}

deny contains msg if {
	not required_actions_present
	msg := "GAP-07: Lambda IAM policy must include dynamodb:PutItem, s3:PutObject, kms:Decrypt, and kms:GenerateDataKey."
}

required_actions_present if {
	lib.policy_actions["dynamodb:PutItem"]
	lib.policy_actions["s3:PutObject"]
	lib.policy_actions["kms:Decrypt"]
	lib.policy_actions["kms:GenerateDataKey"]
}
