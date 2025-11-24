#!/bin/bash
source ./bash_utils.sh

#=== 1. Ensure libraries Installed ===#
libs=("jq" "curl" "git")

# Iterate over the array elements
for item in "${libs[@]}"; do
  echo "Processing item: $item"
  if ! command -v $item &>/dev/null; then
  echo "🌀 Installing $item..."
  apt update && apt install -y $item
else
  echo "✅ $item is already installed"
fi
done






# ttyd on web
gh_install tsl0922/ttyd ttyd.x86_64 /tmp/ttyd && chmod +x /tmp/ttyd
cp /tmp/ttyd /bin
# ttyd -W -p 38033 bash

gh_install go-gost/gost  linux_amd64.tar.gz /tmp/gost.tar.gz
mkdir /tmp/gost
tar -xvf /tmp/gost.tar.gz -C /tmp/gost
cp /tmp/gost/gost /bin

gh_install vi/websocat websocat.x86_64-unknown-linux-musl /tmp/websocat && chmod +x /tmp/websocat
cp /tmp/websocat /bin


gh_install cloudflare/cloudflared cloudflared-linux-amd64  /tmp/cloudflared && chmod +x /tmp/cloudflared
cp /tmp/cloudflared /bin

# https://trzsz.github.io/cn/
gh_install trzsz/trzsz-go linux_x86_64.tar.gz /tmp/trzsz.tar.gz
mkdir /tmp/trzsz
tar -xvf /tmp/trzsz.tar.gz -C /tmp/trzsz/ --strip-component=1
cp /tmp/trzsz/* /bin
# ttyd -W -t enableTrzsz=true bash
# 浏览器打开 ttyd 终端，trz 命令上传文件，tsz xxx 命令下载 xxx 文件

# ddns
gh_install NewFuture/DDNS ddns-glibc-linux_amd64 /tmp/ddns
chmod +x /tmp/ddns 
cp /tmp/ddns /bin

# sshx
curl -sSf https://sshx.io/get | sh

# openlist
gh_install OpenListTeam/OpenList openlist-linux-amd64.tar.gz /tmp/openlist.tar.gz
mkdir /tmp/openlist
tar -xvf /tmp/openlist.tar.gz -C /tmp/openlist
cp /tmp/openlist/openlist /bin

# filen
curl -sL https://filen.io/cli.sh | bash
cp ~/.filen-cli/bin/filen /bin