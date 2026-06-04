package compliance.hipaa.encryption.dynamodb_cmk_test

import rego.v1

import data.compliance.hipaa.encryption.dynamodb_cmk


test_compliant_plan_passes if {
	count(dynamodb_cmk.deny) == 0 with input as data.compliant
}

test_starter_gap_plan_fails if {
	count(dynamodb_cmk.deny) > 0 with input as data.starter_gap
}
