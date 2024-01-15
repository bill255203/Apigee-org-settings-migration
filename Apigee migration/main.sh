#!/bin/bash
# Check if jq is installed
if ! [ -x "$(command -v jq)" ]; then
  echo "jq is not installed. Please install jq to continue."
  exit 1
fi
# Load the configuration from the JSON file
CONFIG_FILE="config.json"
if [[ -f "$CONFIG_FILE" ]]; then
  SOURCE_ORG=$(jq -r '.SOURCE_ORG' "$CONFIG_FILE")
  DEST_ORG=$(jq -r '.DEST_ORG' "$CONFIG_FILE")
  DEST_ACCOUNT=$(jq -r '.DEST_ACCOUNT' "$CONFIG_FILE")
  DEST_DIR=$(jq -r '.DEST_DIR' "$CONFIG_FILE")
else
  echo "Config file not found: $CONFIG_FILE"
  exit 1
fi
# Delete the results directory and its contents, then create a new empty results directory
echo "Resetting results directory..."
# rm -rf "$DEST_DIR"
mkdir -p "$DEST_DIR"
if [ $? -ne 0 ]; then
  echo "Failed to reset results directory."
  exit 1
fi

# Now you can use the variables as needed
echo "SOURCE_ORG: $SOURCE_ORG"
echo "DEST_ORG: $DEST_ORG"
echo "DEST_ACCOUNT: $DEST_ACCOUNT"
echo "DEST_DIR: $DEST_DIR"

# Define an array of script file names
scripts=(
  "sharedflows"
  "sharedflow-deployments"
  "envs"
  "env-flowhooks"
  "kvms"
  "apis"
  "api-deployments"
  "api-kvms"
  "env-kvms"
  "env-targetServers"

  "products"
  "developers"
  "developer-apps"
)

for script in "${scripts[@]}"; do
  source "./get/get-$script.sh"
done

# Generate error file list and check for errors
python3 get-err-files.py
if [ "$(jq length get-err-files.json)" -gt 0 ]; then
  echo "Errors found in GET actions. Aborting..."
  exit 1
fi

# Execute login script
source "./login.sh"

for script in "${scripts[@]}"; do
  source "./post/post-$script.sh"
done

# Generate error file list for POST actions and check for errors
python3 post-err-files.py
if [ "$(jq length post-err-files.json)" -gt 0 ]; then
  echo "Errors found in POST actions. Aborting..."
  exit 1
fi

echo "All operations completed successfully."
