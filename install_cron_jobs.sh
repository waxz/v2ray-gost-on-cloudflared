#!/bin/bash
set -e

#=== 0. Sudo Permission Check ===#
if [ "$EUID" -ne 0 ]; then
  echo "❌ Please run as root (use sudo)"
  exit 1
fi
#=== 1. Install Scripts & Cron Jobs ===#

chmod +x *.sh
sudo cp ./*.sh /bin
sudo cp .vars /opt/.vars

chmod 644 ./cron_proxy_jobs
sed -i s#ubuntu#$USER# ./cron_proxy_jobs
sudo cp ./cron_proxy_jobs /etc/cron.d/
# sudo service cron restart
sudo systemctl restart cron

echo "cron_proxy_jobs installed successfully."
