#!/bin/bash
if [ -z "$JSONBINKEY" ]; then
    echo "JSONBINKEY environment variable is not set."
    exit 1
fi  

url=$(curl  -s https://jsonbin.1248369.xyz/proxy/pinggy/?key=$JSONBINKEY | jq -r ".url")
if [[ -z $url ]]; then echo $? ; echo "" ; exit 0; fi

echo url: $url
ps -A -o tid,cmd  | grep -v grep | grep "gost -L http://:38085" | awk '{print $1}' | xargs -I {} /bin/bash -c ' kill -9  {} '

gost -L http://:38085 -F http+h2://$url?path=/http2