package compliance.hipaa.audit.cloudtrail

import rego.v1

import data.compliance.lib

__rego_metadata__ := {
	"framework": "hipaa",
	"control_id": ["164.312(b)"],
	"severity": "high",
	"description": "Multi-region CloudTrail with log file validation must record API activity for PHI systems.",
	"remediation": "Add aws_cloudtrail with is_multi_region_trail=true and enable_log_file_validation=true.",
}

deny contains msg if {
	not cloudtrail_audit_configured
	msg := "CloudTrail trail must be multi-region with log file validation enabled (164.312(b))."
}

cloudtrail_audit_configured if {
	some resource in lib.resources_by_type("aws_cloudtrail")
	resource.values.is_multi_region_trail == true
	resource.values.enable_log_file_validation == true
}
