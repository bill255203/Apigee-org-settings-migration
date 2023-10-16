# Project Name

Apigee migration implementation

## Prerequisites

- [jq](https://stedolan.github.io/jq/) must be installed.

## Usage

1. Clone the repository.
2. Add your configuration details to `config.json`.
3. Execute `main.sh` to perform the following tasks:
   - Load configuration from `config.json`.
   - Execute various scripts to retrieve and process data.
   - Generate error messages using `*-err-msgs.sh`.

## Configuration

Explain the configuration options in `config.json`:

- `SOURCE_ORG`: Description of the source organization.
- `DEST_ORG`: Description of the destination organization.
- `DEST_ACCOUNT`: Description of the destination account.
- `DEST_DIR`: Description of the destination directory.

## Scripts

### Main Script (`main.sh`)

- Purpose: Describe the overall purpose of the main script.
- Usage: Explain how to run the main script.

### Additional Scripts

#### Get Scripts (`get-*.sh`)

- Purpose: These scripts retrieve Apigee information from the source project.
- Usage: Describe how to use these scripts, and mention that they collect data for further processing.

#### Login Script (`login.sh`)

- Purpose: Explain that this script handles authentication and retrieves necessary credentials.
- Usage: Describe how to run this script and the importance of obtaining credentials.

#### Post Scripts (`post-*.sh`)

- Purpose: These scripts perform actions based on the retrieved data from the source project.
- Usage: Explain that these scripts execute actions such as Apigee migration steps.

#### Error Message Extraction (`*-err-msgs.sh`)

- Purpose: Describe the purpose of the error message extraction script.
- Usage: Explain that this script generates error messages and stores them in `error_message.json` for inspection.

# API Endpoints README

This document outlines the structure of the API endpoints, including available resources and their associated GET and POST requests.

## Products

- List: api_products.json
- GET: ${product_name}\_product_details.json
- POST: ${product_name}\_product_response.json

## Appgroup

- List: appgroups.json
- GET: ${appgroup_name}\_appgroup_details.json
- POST: ${appgroup_name}\_appgroup_response.json

## Appgroup-Apps

- List: appgroup.json
- GET: ${appgroup_name}\_apps_details.json
- GET: ${appgroup_name}\_app_details.json
- POST: ${appgroup_name}\_app_response.json

## Developers

- List: developers.json
- GET: ${email}\_developer_details.json
- POST: ${email}\_developer_response.json

## Developers-Apps

- List: developers_apps.json
- GET: ${email}\_dev_apps_info.json
- GET: ${email}_${appId}\_dev_app_info.json
- POST: ${email}_${appId}\_dev_app_response.json

## Environments

- List: envs.json
- GET: ${environment}\_env_details.json
- POST: ${environment}\_env_response.json

## Env-Group

- List: env_groups.json
- POST: ${env_group_name}\_envgroup_response.json

## Env-Group-Attachments

- List: env_group_attachments.json
- GET: ${envgroup_name}\_envgroup_attachments.json
- POST: ${envgroup_name}\_envgroup_attachments_response.json

## Sharedflow

- List: sharedflows.json
- GET: sharedflow\_${sharedflow_name}.json
- GET: sharedflow\_${sharedflow_name}\_revision\_${revision_number}.zip
- POST: sharedflow\_${sharedflow_name}\_revision\_${revision_number}\_response.json

## Proxies

- List: proxies.json
- GET: proxy\_${proxy_name}\_revision\_${revision}.zip
- POST: proxy\_${proxy_name}\_revision\_${revision}\_response.json
