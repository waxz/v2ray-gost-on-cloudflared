#!/bin/bash


# tty on web
gh_install tsl0922/ttyd ttyd.x86_64 /tmp/ttyd && chmod +x /tmp/ttyd
sudo cp /tmp/ttyd /bin
# ttyd -W -p 38033 bash

# https://trzsz.github.io/cn/
gh_install trzsz/trzsz-go linux_x86_64.tar.gz /tmp/trzsz.tar.gz
mkdir /tmp/trzsz
tar -xvf /tmp/trzsz.tar.gz -C /tmp/trzsz/ --strip-component=1
sudo cp /tmp/trzsz/* /bin
# ttyd -W -t enableTrzsz=true bash
# 浏览器打开 ttyd 终端，trz 命令上传文件，tsz xxx 命令下载 xxx 文件
