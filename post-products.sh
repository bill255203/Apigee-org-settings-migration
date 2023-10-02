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

# Function to create or update an API product
create_or_update_api_product() {
  local product_name="$1"
  local product_details_file="$2"
  echo "Creating or updating API product: $product_name..."
  curl -X POST "https://apigee.googleapis.com/v1/organizations/$DEST_ORG/apiproducts" \
    -H "Authorization: Bearer $SOURCE_TOKEN" \
    -o "$DEST_DIR/${product_name}_response.json" \
    -d @"$product_details_file" \
    -H "Content-Type: application/json"
  echo "API product creation or update response saved to $DEST_DIR/${product_name}_response.json"
}

# Parse the product names as elements in an array
IFS=$'\n' read -d '' -r -a product_names < <(jq -r '.apiProduct[].name' "$DEST_DIR/api_products.json")

# Loop through all API products and create or update them
for product_name in "${product_names[@]}"; do
  create_or_update_api_product "$product_name" "$DEST_DIR/${product_name}_details.json"
done

echo "API product operations completed."
