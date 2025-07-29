#!/bin/bash

if [ -z "$JSONBINKEY" ]; then
    echo "JSONBINKEY environment variable is not set."
    exit 1
fi

if [ -f "/tmp/cloudflared.out" ]; then rm /tmp/cloudflared.out; fi
ps -A -o tid,cmd  | grep -v grep | grep "gost -L=mws://:38083" | awk '{print $1}' | xargs -I {} /bin/bash -c ' kill -9  {} '
ps -A -o tid,cmd  | grep -v grep | grep "cloudflared tunnel --url localhost:38083" | awk '{print $1}' | xargs -I {} /bin/bash -c ' kill -9  {} '

ps -A -o tid,cmd  | grep -v grep | grep "websocat --binary ws-l:127.0.0.1:38022 tcp:127.0.0.1:22" | awk '{print $1}' | xargs -I {} /bin/bash -c ' kill -9  {} '
ps -A -o tid,cmd  | grep -v grep | grep "cloudflared tunnel --url localhost:38022" | awk '{print $1}' | xargs -I {} /bin/bash -c ' kill -9  {} '


#  gost proxy
nohup bash -c "gost -L=mws://:38083?enableCompression=true&keepAlive=true&idletimeout=30s&readBufferSize=64KB" > /tmp/gost.2.out 2>&1 &
# nohup bash -c "while true; do cloudflared tunnel --url localhost:38083   > /tmp/cloudflared.out 2>&1 ;flock -x  /tmp/cloudflared.out  truncate -s 0 /tmp/cloudflared.out;  done " > /tmp/cloudflared.nohup.out 2>&1 &
nohup bash -c "cloudflared tunnel --url localhost:38083   > /tmp/cloudflared.out 2>&1" > /tmp/cloudflared.nohup.out 2>&1 &
cloudflared_url=""
while [ -z "$cloudflared_url" ];do
if [ -s /tmp/cloudflared.out ]; then
    cloudflared_url_new=$(flock -s  /tmp/cloudflared.out   cat /tmp/cloudflared.out | grep -oE "https://[a-zA-Z0-9.-]+\.trycloudflare\.com");
    if [ -z "$cloudflared_url_new" ]; then
        echo "No cloudflared URL found";
    else
        cloudflared_url="${cloudflared_url_new/https:\/\//}"
        echo "Cloudflared URL found:" $cloudflared_url;
    fi
fi;
sleep 1
done

# websocat proxy
nohup bash -c "websocat --binary ws-l:127.0.0.1:38022 tcp:127.0.0.1:22" > /tmp/websocat-ssh.out 2>&1 &
nohup bash -c "cloudflared tunnel --url localhost:38022   > /tmp/cloudflared-ssh.out 2>&1" > /tmp/cloudflared-ssh.nohup.out 2>&1 &
cloudflared_ssh_url=""
while [ -z "$cloudflared_ssh_url" ];do
if [ -s /tmp/cloudflared-ssh.out ]; then
    cloudflared_ssh_url_new=$(flock -s  /tmp/cloudflared-ssh.out   cat /tmp/cloudflared-ssh.out | grep -oE "https://[a-zA-Z0-9.-]+\.trycloudflare\.com");
    if [ -z "$cloudflared_ssh_url_new" ]; then
        echo "No cloudflared SSH URL found";
    else
        cloudflared_ssh_url="${cloudflared_ssh_url_new/https:\/\//}"
        echo "Cloudflared SSH URL found:" $cloudflared_ssh_url;
    fi
fi;
sleep 1
done

curl -s https://jsonbin.1248369.xyz/proxy/cf/?key=$JSONBINKEY -d "{\"url\":\"$cloudflared_url\"}"
curl -s https://jsonbin.1248369.xyz/ssh/cf/?key=$JSONBINKEY -d "{\"url\":\"$cloudflared_ssh_url\"}"
