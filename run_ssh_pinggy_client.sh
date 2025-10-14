#!/bin/bash
if [ -z "$JSONBINKEY" ]; then
    echo "JSONBINKEY environment variable is not set."
    exit 1
fi  

url=$(curl -s "https://jsonbin.1248369.xyz/ssh/pinggy/?key=$JSONBINKEY" | jq -r ".url")
if [[ -z $url ]]; then echo $? ; echo "" ; exit 0; fi

url=${url/":"/" -p "}
echo url: $url
ssh ubuntu@$url  -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i "~/.ssh/aws.pem"