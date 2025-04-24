admin-spec:
	./plugins convert_json_schema --plugins $$(ls schemas/) --version 3.10.x --skip-custom-annotations; cp -r json_schemas/* ../kong-admin-spec-generator/data/plugins