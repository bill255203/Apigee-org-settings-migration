#!/bin/bash

# Specify the source organization, account, and directory
SOURCE_ORG="tw-rd-de-bill"
DEST_ACCOUNT="YOUR_DESTINATION_ACCOUNT"
DEST_DIR="/Users/liaopinrui/Downloads/"

# Get the OAuth 2.0 access token for the source project
SOURCE_TOKEN=$(gcloud auth print-access-token)



# Authenticate with the destination account and get the OAuth token
gcloud auth login "$DEST_ACCOUNT"
DEST_TOKEN=$(gcloud auth print-access-token)