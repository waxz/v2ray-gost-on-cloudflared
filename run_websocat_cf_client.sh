#!/bin/bash
if [ -z "$JSONBINKEY" ]; then
    echo "JSONBINKEY environment variable is not set."
    exit 1
fi  

url=$(curl  -s https://jsonbin.1248369.xyz/ssh/cf/?key=$JSONBINKEY | jq -r ".url")
if [[ -z $url ]]; then echo $? ; echo "" ; exit 0; fi


echo url: $url

ssh ubuntu@$url -o ProxyCommand="websocat -E  --binary wss://%h" -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i "~/.ssh/aws.pem"