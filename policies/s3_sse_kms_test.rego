package compliance.hipaa.encryption.s3_sse_kms_test

import rego.v1

import data.compliance.hipaa.encryption.s3_sse_kms


test_compliant_plan_passes if {
	count(s3_sse_kms.deny) == 0 with input as data.compliant
}

test_starter_gap_plan_fails if {
	count(s3_sse_kms.deny) > 0 with input as data.starter_gap
}
