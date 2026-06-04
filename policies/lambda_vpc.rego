package compliance.hipaa.boundary.lambda_vpc

import rego.v1

import data.compliance.lib

__rego_metadata__ := {
	"framework": "hipaa",
	"control_id": ["164.312(e)(1)"],
	"severity": "high",
	"description": "Lambda handling PHI must run inside the workload VPC with security groups.",
	"remediation": "Add vpc_config block to aws_lambda_function.intake with private subnet_ids and security_group_ids.",
}

deny contains msg if {
	not intake_lambda_in_vpc
	msg := "GAP-05: aws_lambda_function.intake must have vpc_config with subnet_ids and security_group_ids."
}

intake_lambda_in_vpc if {
	some resource in lib.resources_by_type("aws_lambda_function")
	resource.name == "intake"
	vpc_cfg := object.get(resource.values, "vpc_config", [])
	vpc_cfg != []
	count(vpc_cfg[0].subnet_ids) > 0
	count(vpc_cfg[0].security_group_ids) > 0
}
