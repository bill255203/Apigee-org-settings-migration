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

# Get the OAuth 2.0 access token for the source project
SOURCE_TOKEN=$(gcloud auth print-access-token)

echo "Listing API products..."
curl -X GET "https://apigee.googleapis.com/v1/organizations/$SOURCE_ORG/apiproducts" -H "Authorization: Bearer $SOURCE_TOKEN" -o "$DEST_DIR/api_products.json"
echo "API products list saved to $DEST_DIR/api_products.json"

# Function to retrieve details of an API product by name
get_api_product_details() {
  local product_name="$1"
  echo "Retrieving details for API product: $product_name..."
  curl -X GET "https://apigee.googleapis.com/v1/organizations/$SOURCE_ORG/apiproducts/$product_name" -H "Authorization: Bearer $SOURCE_TOKEN" -o "$DEST_DIR/${product_name}_details.json"
  echo "API product details saved to $DEST_DIR/${product_name}_details.json"
}

# Parse the product names as elements in an array
IFS=$'\n' read -d '' -r -a product_names < <(jq -r '.apiProduct[].name' "$DEST_DIR/api_products.json")

# Loop through the product names
echo "List of API product names:"
for product_name in "${product_names[@]}"; do
  echo "$product_name"
done

# Loop through all API products and retrieve details
for product_name in "${product_names[@]}"; do
  get_api_product_details "$product_name"
done
