package compliance.hipaa.transmission.s3_tls_enforcement_test

import rego.v1

import data.compliance.hipaa.transmission.s3_tls_enforcement


test_compliant_plan_passes if {
	count(s3_tls_enforcement.deny) == 0 with input as data.compliant
}

test_starter_gap_plan_fails if {
	count(s3_tls_enforcement.deny) > 0 with input as data.starter_gap
}
