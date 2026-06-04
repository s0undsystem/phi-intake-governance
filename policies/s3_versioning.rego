package compliance.hipaa.contingency.s3_versioning

import rego.v1

import data.compliance.lib

__rego_metadata__ := {
	"framework": "hipaa",
	"control_id": ["164.308(a)(7)"],
	"severity": "medium",
	"description": "S3 uploads bucket must have versioning enabled to recover from PHI overwrites.",
	"remediation": "Add aws_s3_bucket_versioning on the uploads bucket with status Enabled.",
}

deny contains msg if {
	not uploads_versioning_enabled
	msg := "GAP-04: S3 uploads bucket must have versioning enabled."
}

uploads_versioning_enabled if {
	some resource in lib.resources_by_type("aws_s3_bucket_versioning")
	cfg := object.get(resource.values, "versioning_configuration", [])
	cfg != []
	cfg[0].status == "Enabled"
}
