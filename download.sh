#!/bin/bash
source ./bash_utils.sh

# tty on web
gh_install tsl0922/ttyd ttyd.x86_64 /tmp/ttyd && chmod +x /tmp/ttyd
sudo cp /tmp/ttyd /bin
# ttyd -W -p 38033 bash

gh_install go-gost/gost  linux_amd64.tar.gz /tmp/gost.tar.gz
mkdir /tmp/gost
tar -xvf /tmp/gost.tar.gz -C /tmp/gost
sudo cp /tmp/gost/gost /bin

gh_install vi/websocat websocat.x86_64-unknown-linux-musl /tmp/websocat && chmod +x /tmp/websocat
sudo cp /tmp/websocat /bin


gh_install cloudflare/cloudflared cloudflared-linux-amd64  /tmp/cloudflared && chmod +x /tmp/cloudflared
sudo cp /tmp/cloudflared /bin

# https://trzsz.github.io/cn/
gh_install trzsz/trzsz-go linux_x86_64.tar.gz /tmp/trzsz.tar.gz
mkdir /tmp/trzsz
tar -xvf /tmp/trzsz.tar.gz -C /tmp/trzsz/ --strip-component=1
sudo cp /tmp/trzsz/* /bin
# ttyd -W -t enableTrzsz=true bash
# 浏览器打开 ttyd 终端，trz 命令上传文件，tsz xxx 命令下载 xxx 文件

# ddns
gh_install NewFuture/DDNS ddns-glibc-linux_amd64 /tmp/ddns
chmod +x /tmp/ddns 
sudo cp /tmp/ddns /bin

# sshx
curl -sSf https://sshx.io/get | sh
