package compliance.hipaa.audit.cloudtrail_test

import rego.v1

import data.compliance.hipaa.audit.cloudtrail


test_compliant_plan_passes if {
	count(cloudtrail.deny) == 0 with input as data.compliant
}

test_starter_gap_plan_fails if {
	count(cloudtrail.deny) > 0 with input as data.starter_gap
}
