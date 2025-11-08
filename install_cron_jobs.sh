#!/bin/bash
set -e

#=== 0. Sudo Permission Check ===#
if [ "$EUID" -ne 0 ]; then
  echo "❌ Please run as root (use sudo)"
  exit 1
fi

sed -i s#/home/ubuntu/.bashrc#/home/$USER/.bashrc# ./proxy_gost_cf.sh
sed -i s#/home/ubuntu/.bashrc#/home/$USER/.bashrc# ./proxy_gost_pinggy.sh
sed -i s#/home/ubuntu/.bashrc#/home/$USER/.bashrc# ./setup_v2ray.sh

chmod +x *.sh
cp ./*.sh /bin

chmod 644 ./cron_proxy_jobs
sed -i s#ubuntu#$USER# ./cron_proxy_jobs
cp ./cron_proxy_jobs /etc/cron.d/

# sudo service cron restart
systemctl restart cron

echo "cron_proxy_jobs installed successfully."
