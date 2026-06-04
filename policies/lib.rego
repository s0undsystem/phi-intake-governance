package compliance.lib

import rego.v1

all_planned_resources contains resource if {
	resource := input.planned_values.root_module.resources[_]
}

all_planned_resources contains resource if {
	mod := input.planned_values.root_module.child_modules[_]
	resource := mod.resources[_]
}

all_planned_resources contains resource if {
	parent := input.planned_values.root_module.child_modules[_]
	mod := parent.child_modules[_]
	resource := mod.resources[_]
}

all_resource_changes contains change if {
	change := input.resource_changes[_]
}

resources_by_type(type) := [resource |
	some resource in all_planned_resources
	resource.type == type
]

policy_documents contains doc if {
	change := input.resource_changes[_]
	change.type == "aws_iam_role_policy"
	change.change.after != null
	is_string(change.change.after.policy)
	doc := json.unmarshal(change.change.after.policy)
}

policy_documents contains doc if {
	resource := all_planned_resources[_]
	resource.type == "aws_iam_role_policy"
	is_string(resource.values.policy)
	doc := json.unmarshal(resource.values.policy)
}

policy_statements contains stmt if {
	doc := policy_documents[_]
	stmt := doc.Statement[_]
}

policy_actions contains action if {
	stmt := policy_statements[_]
	action := stmt.Action[_]
}

policy_actions contains action if {
	stmt := policy_statements[_]
	is_string(stmt.Action)
	action := stmt.Action
}
