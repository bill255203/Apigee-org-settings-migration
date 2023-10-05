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
   - Generate error messages using `extract_error_messages.sh`.

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

#### Error Message Extraction (`extract_error_messages.sh`)

- Purpose: Describe the purpose of the error message extraction script.
- Usage: Explain that this script generates error messages and stores them in `error_message.json` for inspection.
