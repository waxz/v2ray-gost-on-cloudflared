#!/bin/bash


# tty on web
gh_install tsl0922/ttyd ttyd.x86_64 /tmp/ttyd && chmod +x /tmp/ttyd
sudo /tmp/ttyd /bin
# ttyd -W -p 38033 bash