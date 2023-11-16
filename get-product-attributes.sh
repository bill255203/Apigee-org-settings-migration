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

# Parse the product names from the response
apiproducts=($(cat "$DEST_DIR/api_products.json" | jq -r '.[]'))

# Loop through each product and perform GET and POST requests
for product in "${apiproducts[@]}"; do
  echo "Processing product: $product"

  # Make a GET request to get product details
  get_attr_response=$(curl -X GET "https://apigee.googleapis.com/v1/organizations/$SOURCE_ORG/apiproducts/$product/attributes" -H "Authorization: Bearer $SOURCE_TOKEN")

  # Save the response for the product details to a file
  echo "$get_attr_response" > "$DEST_DIR/${product}_product_attributes_details.json"

  echo "product details saved to $DEST_DIR/${product}_product_attributes_details.json"

  attrs=($(cat "$DEST_DIR/${product}_product_attributes_details.json" | jq -r '.attribute[]'))

  for attr in "${attrs[@]}"; do    
    
    # Make a GET request to get product details
    get_attr_response=$(curl -X GET "https://apigee.googleapis.com/v1/organizations/$SOURCE_ORG/apiproducts/$product/attributes/$attr" -H "Authorization: Bearer $SOURCE_TOKEN")
    
    # Make a GET request to get product details
    get_rateplan_response=$(curl -X GET "https://apigee.googleapis.com/v1/organizations/$SOURCE_ORG/apiproducts/$product/attributes/$rateplans" -H "Authorization: Bearer $SOURCE_TOKEN")

    # Save the response for the product details to a file
    echo "$get_attr_response" > "$DEST_DIR/${product}_product_${attr}_attribute_details.json"

    echo "product details saved to $DEST_DIR/${product}_product_${attr}_attribute_details.json"

    echo "$get_rateplan_response" > "$DEST_DIR/${product}_product_rateplan_details.json"

    echo "product details saved to $DEST_DIR/${product}_product_rateplan_details.json"

  done
done

echo "product operations completed."
