#!/bin/bash
source /home/ubuntu/.bashrc

if [ -f "/home/ubuntu/.bashrc" ]; then
  . "/home/ubuntu/.bashrc"
  JSONBINKEY=$(grep -oP '(?<=^export JSONBINKEY=).*' /home/ubuntu/.bashrc)

  temp="${JSONBINKEY%\"}"
  JSONBINKEY="${temp#\"}"

  if [ -z "$JSONBINKEY" ]; then
    echo "JSONBINKEY environment variable is not set in .bashrc."
    exit 1
  fi


fi
# Ensure the user's .bashrc is sourced
# Check if JSONBINKEY is set
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

sleep 10
# websocat proxy
nohup bash -c "websocat --binary ws-l:127.0.0.1:38022 tcp:127.0.0.1:22" > /tmp/websocat-ssh.out 2>&1 &
nohup bash -c "cloudflared tunnel --url localhost:38022   > /tmp/cloudflared-ssh.out 2>&1" > /tmp/cloudflared-ssh.nohup.out 2>&1 &

sleep 10
# ttyd server
nohup bash -c "ttyd -W -p 38033 bash" > /tmp/websocat-ttyd.out 2>&1 &
nohup bash -c "cloudflared tunnel --url localhost:38033   > /tmp/cloudflared-ttyd.out 2>&1" > /tmp/cloudflared-ttyd.nohup.out 2>&1 &


cloudflared_url=""
cloudflared_ssh_url=""
cloudflared_ttyd_url=""

# progress bar
i=1
sp="*x/-\|"
echo -n ' '

while [ "true" ];do 

    cmd_content=$(curl -s https://jsonbin.1248369.xyz/aws/cmd?key=$JSONBINKEY)


    if [ -s /tmp/cloudflared.out ]; then
        cloudflared_url_new=$(flock -s  /tmp/cloudflared.out   cat /tmp/cloudflared.out | grep -oE "https://[a-zA-Z0-9.-]+\.trycloudflare\.com");
        if [ -z "$cloudflared_url_new" ]; then
            echo "No cloudflared URL found";
        else
            cloudflared_url_new="${cloudflared_url_new/https:\/\//}"
            if [ "$cloudflared_url" == "$cloudflared_url_new"  ]; then
                printf "\b${sp:i++%${#sp}:1}";
            else
                cloudflared_url="$cloudflared_url_new" ;
                curl -s https://jsonbin.1248369.xyz/proxy/cf/?key=$JSONBINKEY -d "{\"url\":\"$cloudflared_url\"}"
            fi
            echo "Cloudflared URL found:" $cloudflared_url;
            cmd=$(echo $cmd_content | jq -r ".proxy_cmd")
            
            if [ "restart" == "$cmd" ]; then
                curl -s https://jsonbin.1248369.xyz/aws/cmd?key=$JSONBINKEY -d "{}"
                echo "Running command: ${cmd}"
                rm /tmp/cloudflared.out
                ps -A -o tid,cmd  | grep -v grep | grep "cloudflared tunnel --url localhost:38083" | awk '{print $1}' | xargs -I {} /bin/bash -c ' kill -9  {} '
                nohup bash -c "cloudflared tunnel --url localhost:38083   > /tmp/cloudflared.out 2>&1" > /tmp/cloudflared.nohup.out 2>&1 &

            fi;
        fi;
    fi;
if [ -s /tmp/cloudflared-ssh.out ]; then
    cloudflared_ssh_url_new=$(flock -s  /tmp/cloudflared-ssh.out   cat /tmp/cloudflared-ssh.out | grep -oE "https://[a-zA-Z0-9.-]+\.trycloudflare\.com");
    if [ -z "$cloudflared_ssh_url_new" ]; then
        echo "No cloudflared SSH URL found";
    else
        cloudflared_ssh_url_new="${cloudflared_ssh_url_new/https:\/\//}"
        if [ "$cloudflared_ssh_url" == "$cloudflared_ssh_url_new"  ]; then
            printf "\b${sp:i++%${#sp}:1}";
        else
            cloudflared_ssh_url="$cloudflared_ssh_url_new" ;
            curl -s https://jsonbin.1248369.xyz/ssh/cf/?key=$JSONBINKEY -d "{\"url\":\"$cloudflared_ssh_url\"}"
        fi
        echo "Cloudflared SSH URL found:" $cloudflared_ssh_url;
        cmd=$(echo $cmd_content | jq -r ".ssh_cmd")
        
        if [ "restart" == "$cmd" ]; then
            curl -s https://jsonbin.1248369.xyz/aws/cmd?key=$JSONBINKEY -d "{}"
            echo "Running command: ${cmd}"
            rm /tmp/cloudflared-ssh.out
            ps -A -o tid,cmd  | grep -v grep | grep "cloudflared tunnel --url localhost:38022" | awk '{print $1}' | xargs -I {} /bin/bash -c ' kill -9  {} '
            nohup bash -c "cloudflared tunnel --url localhost:38022   > /tmp/cloudflared-ssh.out 2>&1" > /tmp/cloudflared-ssh.nohup.out 2>&1 &

        fi
    fi
fi;
if [ -s /tmp/cloudflared-ttyd.out ];
    cloudflared_ttyd_url_new=$(flock -s  /tmp/cloudflared-ttyd.out   cat /tmp/cloudflared-ttyd.out | grep -oE "https://[a-zA-Z0-9.-]+\.trycloudflare\.com");
    if [ -z "$cloudflared_ttyd_url_new" ]; then
        echo "No cloudflared ttyd URL found";
    else
        cloudflared_ttyd_url_new="${cloudflared_ttyd_url_new/https:\/\//}"
        if [ "$cloudflared_ttyd_url" == "$cloudflared_ttyd_url_new"  ]; then
            printf "\b${sp:i++%${#sp}:1}";
        else
            cloudflared_ttyd_url="$cloudflared_ttyd_url_new" ;
            curl -s https://jsonbin.1248369.xyz/ttyd/aws/?key=$JSONBINKEY -d "{\"url\":\"$cloudflared_ttyd_url\"}"
        fi
        echo "Cloudflared ttyd URL found:" $cloudflared_ttyd_url;
        cmd=$(echo $cmd_content | jq -r ".ttyd_cmd")
        
        if [ "restart" == "$cmd" ]; then
            curl -s https://jsonbin.1248369.xyz/aws/cmd?key=$JSONBINKEY -d "{}"
            echo "Running command: ${cmd}"
            rm /tmp/cloudflared-ttyd.out
            ps -A -o tid,cmd  | grep -v grep | grep "cloudflared tunnel --url localhost:38033" | awk '{print $1}' | xargs -I {} /bin/bash -c ' kill -9  {} '
            nohup bash -c "cloudflared tunnel --url localhost:38033   > /tmp/cloudflared-ttyd.out 2>&1" > /tmp/cloudflared-ttyd.nohup.out 2>&1 &

        fi
    fi

fi
sleep 60
done