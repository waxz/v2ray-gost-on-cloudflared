# bash_scripts
scripts to setup proxy on linux/windows, cloudflared tunnel urls are stored in [JSONBIN](https://github.com/waxz/json-bin)

- gost server/client over cloudflare tunnel
- ssh/ttyd over cloudflare tunnel
- v2raya on windows
- tor on linux

## windows

### setup v2raya
```shell
./download_v2raya.ps1

./run_v2ray.ps1
```

### setup gost proxy client
```shell
./proxy_gost_cf.ps1
```

## linux

### setup gost proxy server
```bash
./proxy_gost_cf.sh
```

### setup gost proxy client
```bash
./run_gost_cf_client.sh
```

### cron
https://askubuntu.com/questions/2368/how-do-i-set-up-a-cron-job
https://stackoverflow.com/questions/10193788/restarting-cron-after-changing-crontab-file
https://unix.stackexchange.com/questions/458713/how-are-files-under-etc-cron-d-used
https://askubuntu.com/questions/1216322/error-bad-username-while-reading-etc-crontab
https://unix.stackexchange.com/questions/67940/cron-ignores-variables-defined-in-bashrc-and-bash-profile
https://stackoverflow.com/questions/9733338/remove-first-and-last-quote-from-a-variable
