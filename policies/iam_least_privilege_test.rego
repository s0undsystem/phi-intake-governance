package compliance.hipaa.access.iam_least_privilege_test

import rego.v1

import data.compliance.hipaa.access.iam_least_privilege


test_compliant_plan_passes if {
	count(iam_least_privilege.deny) == 0 with input as data.compliant
}

test_starter_gap_plan_fails if {
	count(iam_least_privilege.deny) > 0 with input as data.starter_gap
}
