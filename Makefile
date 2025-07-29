admin-spec:
	./plugins convert_json_schema --plugins $$(ls schemas/) --version 3.11.x --skip-custom-annotations --allow-auto-fields; cp -r json_schemas/* ../kong-admin-spec-generator/data/plugins