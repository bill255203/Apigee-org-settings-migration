#!/bin/bash

# Directory containing the JSON files
json_dir="/Users/liaopinrui/Downloads/"

# Output JSON file in the same directory as the script
output_file="$(dirname "$0")/get-err-msgs.json"

# Truncate the output file to clear its content
> "$output_file"

# Flag to track if an error message indicates a stop condition
stop_flag=0

# Iterate through JSON files in the directory
for json_file in "${json_dir}"*.json; do
  # Check if the file is not the output file itself
  if [ "$json_file" != "$output_file" ]; then
    # Extract the error code, message, and status from the JSON file using jq
    error_code=$(jq -r '.error.code' "$json_file")
    error_message=$(jq -r '.error.message' "$json_file")
    error_status=$(jq -r '.error.status' "$json_file")

    # If error_code is null, set it to "null"
    if [ "$error_code" == "null" ]; then
      error_code="null"
    fi

    # Get the file name without the directory path
    file_name=$(basename "$json_file")

    # Create a JSON object with the error code, message, status, and file name
    error_entry="{\"file\": \"$file_name\", \"error_code\": $error_code, \"error_message\": \"$error_message\", \"error_status\": \"$error_status\"}"

    # Append the error entry to the output JSON file
    echo "$error_entry" >> "$output_file"

    # Check if the error_message is not "null" and not an empty string
    if [ "$error_message" != "null" ] && [ -n "$error_message" ]; then
      # Check if the error_message is not "409"
      if [ "$error_message" != "409" ]; then
        stop_flag=1
        break  # Exit the loop immediately
      fi
    fi
  fi
done

echo "Script completed. Results are stored in $output_file"

# Set the exit code based on the stop condition
if [ $stop_flag -eq 1 ]; then
  exit 1  # Exit with a non-zero code to indicate an error
fi
