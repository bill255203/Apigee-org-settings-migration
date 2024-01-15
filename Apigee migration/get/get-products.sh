#!/bin/bash

# Import the JSON configuration
CONFIG_FILE="config.json"
if [[ -f "$CONFIG_FILE" ]]; then
  source <(jq -r 'to_entries | .[] | "export \(.key)=\(.value)"' "$CONFIG_FILE")
else
  echo "Config file not found: $CONFIG_FILE"
  exit 1
fi

# Now you can use the parameters in this script
echo "SOURCE_ORG in env.sh: $SOURCE_ORG"
echo "DEST_ORG in env.sh: $DEST_ORG"
echo "DEST_ACCOUNT in env.sh: $DEST_ACCOUNT"
echo "DEST_DIR in env.sh: $DEST_DIR"

# Create necessary directories for storing the results
mkdir -p "$DEST_DIR/get/product"
mkdir -p "$DEST_DIR/get-err/product"

# Get the OAuth 2.0 access token for the source project
SOURCE_TOKEN=$(gcloud auth print-access-token)

# Make the initial API call
api_products_list_file="$DEST_DIR/get/product/api-products_src.json"
error_api_products_list_file="$DEST_DIR/get-err/product/api-products_src_error.json"
status_code=$(curl -s -o "$api_products_list_file" -w "%{http_code}" -X GET "https://apigee.googleapis.com/v1/organizations/$SOURCE_ORG/apiproducts" -H "Authorization: Bearer $SOURCE_TOKEN")

if [[ "$status_code" -ne 200 ]]; then
  echo "Error retrieving API products list, HTTP status code: $status_code"
  mv "$api_products_list_file" "$error_api_products_list_file"
  exit 1
fi

echo "API products list saved to $api_products_list_file"

# Function to retrieve src of an API product by name
get_api_product_src() {
  local product_name="$1"
  local transformed_name=$(echo "$product_name" | tr ' ' '+') # Replace space with plus
  local response_file="$DEST_DIR/get/product/product_${transformed_name}_src.json"
  local error_file="$DEST_DIR/get-err/product/product_${transformed_name}_src_error.json"

  echo "Retrieving src for API product: $product_name..."
  status_code=$(curl -s -o "$response_file" -w "%{http_code}" -X GET "https://apigee.googleapis.com/v1/organizations/$SOURCE_ORG/apiproducts/$transformed_name" -H "Authorization: Bearer $SOURCE_TOKEN")

  if [[ "$status_code" -ne 200 ]]; then
    echo "Error retrieving src for API product $product_name, HTTP status code: $status_code"
    mv "$response_file" "$error_file"
  else
    echo "API product src saved to $response_file"
  fi
}

# Parse the product names as elements in an array
product_names=($(jq -r '.apiProduct[].name' "$api_products_list_file"))

# Loop through all API products and retrieve src
for product_name in "${product_names[@]}"; do
  get_api_product_src "$product_name"
done

echo "API product src retrieval operations completed."
