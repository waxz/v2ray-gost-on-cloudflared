
#!/bin/bash

if [ -z "$JSONBINKEY" ]; then
    echo "JSONBINKEY environment variable is not set."
    exit 1
fi

chmod +x ./proxy_gost_cf.sh
sudo cp ./proxy_gost_cf.sh /bin/proxy_gost_cf.sh

chmod 644 ./proxy_gost_cf.job
sudo cp ./proxy_gost_cf.job /etc/cron.d/

sudo service cron restart

echo "proxy_gost_cf.sh installed successfully."
echo "starting proxy_gost_cf.sh"
nohup /bin/proxy_gost_cf.sh > /tmp/proxy_gost_cf.out 2>&1 &
