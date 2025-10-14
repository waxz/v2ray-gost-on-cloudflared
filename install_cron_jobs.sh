
#!/bin/bash

if [ -z "$JSONBINKEY" ]; then
    echo "JSONBINKEY environment variable is not set."
    exit 1
fi

chmod +x ./proxy_gost_cf.sh
sed -i s#/home/ubuntu/.bashrc#/home/$USER/.bashrc# ./proxy_gost_cf.sh

sudo cp ./proxy_gost_cf.sh /bin/

chmod +x ./proxy_gost_pinggy.sh
sed -i s#/home/ubuntu/.bashrc#/home/$USER/.bashrc# ./proxy_gost_pinggy.sh

sudo cp ./proxy_gost_pinggy.sh /bin/

chmod +x ./vps_auto_reboot.sh
sudo cp ./vps_auto_reboot.sh /bin/

chmod +x ./run_v2ray.sh
sed -i s#/home/ubuntu/.bashrc#/home/$USER/.bashrc# ./run_v2ray.sh

sudo cp ./run_v2ray.sh /bin/

chmod 644 ./cron_proxy_jobs
sed -i s#ubuntu#$USER# ./cron_proxy_jobs
sudo cp ./cron_proxy_jobs /etc/cron.d/

# sudo service cron restart
sudo systemctl restart cron

echo "proxy_gost_cf.sh installed successfully."
echo "starting proxy_gost_cf.sh"
nohup /bin/proxy_gost_cf.sh > /tmp/proxy_gost_cf.out 2>&1 &
