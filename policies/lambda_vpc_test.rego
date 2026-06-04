package compliance.hipaa.boundary.lambda_vpc_test

import rego.v1

import data.compliance.hipaa.boundary.lambda_vpc


test_compliant_plan_passes if {
	count(lambda_vpc.deny) == 0 with input as data.compliant
}

test_starter_gap_plan_fails if {
	count(lambda_vpc.deny) > 0 with input as data.starter_gap
}
