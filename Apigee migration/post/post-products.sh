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

# Create necessary directories for storing POST request results
mkdir -p "$DEST_DIR/post/product"
mkdir -p "$DEST_DIR/post-err/product"

# Parse the product names as elements in an array
product_names=($(jq -r '.apiProduct[].name' "$DEST_DIR/get/product/api-products_src.json"))

# Loop through all API products and create or update them
for product_name in "${product_names[@]}"; do
  echo "Creating or updating API product: $product_name..."
  product_src_file="$DEST_DIR/get/product/product_${product_name}_src.json"

  # Define file paths for response and error
  response_file="$DEST_DIR/post/product/product_${product_name}_dst.json"
  error_file="$DEST_DIR/post-err/product/product_${product_name}_dst_error.json"

  # Perform the POST request
  status_code=$(curl -s -o "$response_file" -w "%{http_code}" -X POST "https://apigee.googleapis.com/v1/organizations/$DEST_ORG/apiproducts" \
    -H "Authorization: Bearer $DEST_TOKEN" \
    -d @"$product_src_file" \
    -H "Content-Type: application/json")

  if [[ $status_code == 2* ]]; then
    echo "API product creation or update dst saved to $response_file"
  else
    echo "Error creating or updating API product $product_name, HTTP status code: $status_code"
    mv "$response_file" "$error_file"
  fi
done

echo "API product operations completed."
