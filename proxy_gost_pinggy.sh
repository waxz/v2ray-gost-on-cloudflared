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

  PINGGY_TOKEN=$(grep -oP '(?<=^export PINGGY_TOKEN=).*' /home/ubuntu/.bashrc)

  temp="${PINGGY_TOKEN%\"}"
  PINGGY_TOKEN="${temp#\"}"

  if [ -z "$PINGGY_TOKEN" ]; then
    echo "PINGGY_TOKEN environment variable is not set in .bashrc."
    exit 1
  fi
  PINGGY_SSH_TOKEN=$(grep -oP '(?<=^export PINGGY_SSH_TOKEN=).*' /home/ubuntu/.bashrc)

  temp="${PINGGY_SSH_TOKEN%\"}"
  PINGGY_SSH_TOKEN="${temp#\"}"

  if [ -z "$PINGGY_SSH_TOKEN" ]; then
    echo "PINGGY_SSH_TOKEN environment variable is not set in .bashrc."
    exit 1
  fi
fi
# Ensure the user's .bashrc is sourced
# Check if JSONBINKEY is set
if [ -z "$JSONBINKEY" ]; then
    echo "JSONBINKEY environment variable is not set."
    exit 1
fi

if [ -f "/tmp/pinggy.out" ]; then rm /tmp/pinggy.out; fi
if [ -f "/tmp/pinggy_ssh.out" ]; then rm /tmp/pinggy_ssh.out; fi

ps -A -o tid,cmd  | grep -v grep | grep "gost -L http+h2://:38082" | awk '{print $1}' | xargs -I {} /bin/bash -c ' kill -9  {} '
ps -A -o tid,cmd  | grep -v grep | grep "ssh -p 443 -R0:localhost:38082" | awk '{print $1}' | xargs -I {} /bin/bash -c ' kill -9  {} '
ps -A -o tid,cmd  | grep -v grep | grep "ssh -p 443 -R0:localhost:22" | awk '{print $1}' | xargs -I {} /bin/bash -c ' kill -9  {} '

nohup bash -c "gost -L http+h2://:38082?path=/http2" > /tmp/gost.2.out 2>&1 &

nohup bash -c "while true; do ssh -p 443 -R0:localhost:38082 -o StrictHostKeyChecking=no -o ServerAliveInterval=30 $PINGGY_TOKEN+tcp@free.pinggy.io  > /tmp/pinggy.out ;flock -x  /tmp/pinggy.out  truncate -s 0 /tmp/pinggy.out;  done " > /tmp/pinggy.nohup.out 2>&1 &

nohup bash -c "while true; do ssh -p 443 -R0:localhost:22 -o StrictHostKeyChecking=no -o ServerAliveInterval=30 $PINGGY_SSH_TOKEN+tcp@free.pinggy.io  > /tmp/pinggy_ssh.out ;flock -x  /tmp/pinggy_ssh.out  truncate -s 0 /tmp/pinggy_ssh.out;  done " > /tmp/pinggy_ssh.nohup.out 2>&1 &

pinggy_url=""
pinggy_ssh_url=""
while [ "true" ];do
if [ -s /tmp/pinggy.out ]; then
    pinggy_url_new=$(flock -s  /tmp/pinggy.out  cat  /tmp/pinggy.out | grep -oE "tcp://[a-zA-Z0-9.-]+\.pinggy\.link:[0-9.-]+");
    if [ -z "$pinggy_url_new" ]; then
        echo "No pinggy URL found";
    else
        pinggy_url_new="${pinggy_url_new/tcp:\/\//}"
        if [ "$pinggy_url" == "$pinggy_url_new"  ]; 
        then 
            echo "not updated" ; 
        else 
            pinggy_url="$pinggy_url_new" ;
            curl -s https://jsonbin.1248369.xyz/proxy/pinggy/?key=$JSONBINKEY -d "{\"url\":\"$pinggy_url\"}"
        fi

        echo "Pinggy URL found:" $pinggy_url;
    fi
fi
if [ -s /tmp/pinggy_ssh.out ]; then
    pinggy_ssh_url_new=$(flock -s  /tmp/pinggy_ssh.out  cat  /tmp/pinggy_ssh.out | grep -oE "tcp://[a-zA-Z0-9.-]+\.pinggy\.link:[0-9.-]+");
    if [ -z "$pinggy_ssh_url_new" ]; then
        echo "No pinggy SSH URL found";
    else
        pinggy_ssh_url_new="${pinggy_ssh_url_new/tcp:\/\//}"
        if [ "$pinggy_ssh_url" == "$pinggy_ssh_url_new"  ]; 
        then 
            echo "not updated" ; 
        else 
            pinggy_ssh_url="$pinggy_ssh_url_new" ;
            curl -s https://jsonbin.1248369.xyz/ssh/pinggy/?key=$JSONBINKEY -d "{\"url\":\"$pinggy_ssh_url\"}"
        fi
        echo "Pinggy SSH URL found:" $pinggy_ssh_url;
    fi
fi
sleep 1
done

