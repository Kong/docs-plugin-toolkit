# kong-plugins-docs-toolkit

## Install dependencies

```
gem install thor
```

## Usage

This toolkit requires an instance of [Kong Gateway Admin API](https://docs.konghq.com/gateway/latest/admin-api/) to be up and running (make sure you are running the Enterprise version). Most of the commands generate requests under the hood against the API.

### Running different versions of Kong Gateway Admin API locally
The easiest way to run a specific version of the Admin API is with [Gojira](https://github.com/Kong/gojira/tree/master). It provides several [options](https://github.com/Kong/gojira/blob/master/docs/manual.md), but using [kong images](https://github.com/Kong/gojira/blob/master/docs/manual.md#using-kong-release-images-with-gojira) is probably the safest one.

Note: By default, `Gojira` binds ports to random available ones on the host, so you probably want to [bind them to specific ports](https://github.com/Kong/gojira/blob/master/docs/manual.md#bind-ports-on-the-host). By default, the `toolkit` expects `host` to be `localhost` and `port` `8001`.

### Demo

https://user-images.githubusercontent.com/715229/220340450-5006aefe-e7e4-4b45-9272-d0e8b4543878.mov

## Commands

Before running any of the commands, make sure you have the right version of Kong Gateway Admin API running.

### Download Schemas

Downloads the schemas in json format for the specified list of plugins and writes them into disk. Each schema will be stored under `<destination>/<plugin-name>/<version>.json`

| Options | Descriptions  |
|--------------------------- |-----|
| `version` | **Required**. Kong Gateway release version, e.g. `3.3.x`. |
| `plugins` | **Required**. Space separated list of plugins for which the schemas will be downloaded, .e.g. `acme acl`.  Setting it to `$(ls ./schemas)` will download the schemas for all the plugins. |
| `host` | Name of the host in which the API is running. Default: `localhost`.  |
| `port` | Port in which the API is listening. Default: `8001`. |
| `destination` | Path to the root folder in which the schemas will be stored. Default: `./schemas`  |

Downloading the schema for `acme`:
```bash
./plugins download_schemas --version=3.3.x --plugins acme
```

Downloading schemas for all the plugins:
```bash
./plugins download_schemas --version=3.3.x --plugins $(ls ./schemas)
```

### Validate Examples

Validates plugin examples config against the plugin schema using the [Admin API](https://docs.konghq.com/gateway/latest/admin-api/#validate-a-plugin-configuration-against-the-schema). It will iterate over the specified list of plugins and check whether the example for the specified version is valid.

| Options | Descriptions  |
|--------------------------- |-----|
| `version` | **Required**. Kong Gateway release version, e.g. `3.3.x`. |
| `plugins` | **Required**. Space separated list of plugins to use, .e.g. `acme acl`. |
| `host` | Name of the host in which the API is running. Default: `localhost`.  |
| `port` | Port in which the API is listening. Default: `8001`. |
| `source` | Path to the root folder containing the examples. Default: `./examples`.  |

For example, running:
```
./plugins validate_examples --version 3.4.x --plugins acme --verbose
```
reads the file `./examples/acme/_3.4.x.yaml` and validates it against the schema using the API.


### Copy Examples

Copies the last  (ordered by version) example file stored in `<source>/<plugin-name>/` and writes it to `<source>/<plugin-name>/<version>`.

| Options | Descriptions  |
|--------------------------- |-----|
| `version` |  **Required**. Kong Gateway release version, e.g. `3.3.x`. The new example file is named after it.  |
| `plugins` | **Required**. Space separated list of plugins to use, .e.g. `acme acl`.  |
| `source` | Path to the root folder containing the exisitng examples. Default: `./examples`. |

For example, running:
```bash
./plugins copy_examples --version 3.5.x --plugins acme
```
copies the previous example (assuming the previous version is `3.4.x`,  it copies `./examples/acme/_3.4.x.yaml`) and generates a new file `./examples/acme/_3.5.x.yaml`

### Generate Referenceable Fields List

| Options | Descriptions  |
|--------------------------- |-----|
| `version` | **Required**. Kong Gateway release version, e.g. `3.3.x`. |
| `plugins` | **Required**. Space separated list of plugins to use, .e.g. `acme acl`. |
| `source` | Path to the folder containing the plugin schemas. Default: `./schemas`.  |
| `destination` | Path to the root folder in which the file will be stored. Default: `./data`  |

For example, running:
```bash
./plugins generate_referenceable_fields_list --version 3.4.x --plugins $(ls ./schemas)
```
generates a file `./data/referenceable_fields/3.4.x.json` containing a list of plugins that have referenceable fields, and their corresponding referenceable fields.

### Generate Plugin Priorities

| Options | Descriptions  |
|--------------------------- |-----|
| `version` | **Required**. Kong Gateway release version, e.g. `3.3.x`. |
| `host`    | Name of the host in which the API is running. Default: `localhost`.  |
| `port`    | Port in which the API is listening. Default: `8001`. |
| `type`    | Whether the API is running the `Enterprise` or `OSS` edition. Enum: `oss` or `ee`.  |
| `destination` | Path to the root folder in which the file will be stored. Default: `./data`  |

NOTE: when generating priorities for enterprise, make sure the appdynamics plugin is installed

For example, running:
```bash
./plugins generate_plugin_priorities --type=ee --version 3.4.x
```
generates a file `./data/priorities/ee/3.4.x.json` containing a list of plugins and their corresponded priorities order by priority (desc).

### Copy Schemas

Copies the last  (ordered by version) schema file stored in `<source>/<plugin-name>/` and writes it to `<source>/<plugin-name>/<version>`.

| Options | Descriptions  |
|--------------------------- |-----|
| `version` |  **Required**. Kong Gateway release version, e.g. `3.3.x`. The new example file is named after it.  |
| `plugins` | **Required**. Space separated list of plugins to use, .e.g. `acme acl`.  |
| `source` | Path to the root folder containing the exisitng examples. Default: `./schemas`. |

For example, running:
```bash
./plugins copy_schemas --version 3.5.x --plugins acme
```
copies the previous schema (assuming the previous version is `3.4.x`,  it copies `./schemas/acme/3.4.x.json`) and generates a new file `./schemas/acme/3.5.x.json`

### Copy Data files

Copies the last  (ordered by version) data files file stored in `./<source>/**/*/` and writes it to `./<source>/**/*/<version>`.

| Options | Descriptions  |
|--------------------------- |-----|
| `version` |  **Required**. Kong Gateway release version, e.g. `3.3.x`. The new data file is named after it.  |
| `source` | Path to the root folder containing the exisitng examples. Default: `./data`. |

Example:
```bash
./plugins copy_data_files --version 3.5.x
```

### Generate JSON Schemas

Converts schemas into JSON schemas.

| Options | Descriptions  |
|--------------------------- |-----|
| `version` |  **Required**. Kong Gateway release version, e.g. `3.3.x`. The new example file is named after it.  |
| `plugins` | **Required**. Space separated list of plugins to use, .e.g. `acme acl`.  |
| `source`  | Path to the root folder containing the exisiting schemas. Default: `./schemas`. |

For example, running:
```bash
./plugins convert_json_schema --version 3.9.x --plugins acme
```
converts `./schemas/acme/3.9.x.json` into a valid JSON schema and writes it to `./json_schemas/acme/3.9.json`.

## Updating the repo after a new release

Whenever a new version of Kong Gateway is released, we need run the following commands in order. For all of them, specify all the plugins `--plugins $(ls ./schemas)`

1. Download Schemas - specify the new version `x.x.x`
1. Copy Examples - specify the previous version `x.x.y` of the example that gets copied
1. Validate Examples  - specify the new version `x.x.x`
1. Generate Referenceable Fields List - specify the new version `x.x.x`
1. Generate Priorities List - for `oss` and `ee` and specify the new version `x.x.x`
