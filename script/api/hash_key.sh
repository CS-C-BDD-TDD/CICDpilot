#!/bin/bash

api_key=$1
passphrase=$2
api_key_combined="$api_key@$passphrase"
api_key_hash=`echo -n $api_key_combined | sha256sum | awk '{print $1}'`

export API_KEY=$api_key
export api_key=$api_key
export API_KEY_HASH=$api_key_hash
export api_key_hash=$api_key_hash

echo "API Key: $api_key"
echo "API Key Hash: $api_key_hash"
echo "URL Parameters: ?api_key=$api_key&api_key_hash=$api_key_hash"
