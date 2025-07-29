#!/bin/bash
if [ -z "$JSONBINKEY" ]; then
    echo "JSONBINKEY environment variable is not set."
    exit 1
fi  

url=$(curl  -s https://jsonbin.1248369.xyz/proxy/cf/?key=$JSONBINKEY | jq -r ".url")
if [[ -z $url ]]; then echo $? ; echo "" ; exit 0; fi


echo url: $url

gost -L=:38083 -F=mwss://$url:443?enableCompression=true&keepAlive=1