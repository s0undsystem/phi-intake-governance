package compliance.hipaa.contingency.s3_versioning_test

import rego.v1

import data.compliance.hipaa.contingency.s3_versioning


test_compliant_plan_passes if {
	count(s3_versioning.deny) == 0 with input as data.compliant
}

test_starter_gap_plan_fails if {
	count(s3_versioning.deny) > 0 with input as data.starter_gap
}
