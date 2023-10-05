#!/bin/bash

# Directory containing the JSON files
json_dir="/Users/liaopinrui/Downloads/"

# Output JSON file in the same directory as the script
output_file="$(dirname "$0")/error_message.json"

# Truncate the output file to clear its content
> "$output_file"

# Iterate through JSON files in the directory
for json_file in "${json_dir}"*.json; do
  # Check if the file is not the output file itself
  if [ "$json_file" != "$output_file" ]; then
    # Extract the error code from the JSON file using jq
    error_code=$(jq -r '.error.code' "$json_file")

    # If error_code is null, set it to "null"
    if [ "$error_code" == "null" ]; then
      error_code="null"
    fi

    # Get the file name without the directory path
    file_name=$(basename "$json_file")

    # Create a JSON object with the error code and file name
    error_entry="{\"file\": \"$file_name\", \"error_code\": $error_code}"

    # Append the error entry to the output JSON file
    echo "$error_entry" >> "$output_file"
  fi
done

echo "Script completed. Results are stored in $output_file"
