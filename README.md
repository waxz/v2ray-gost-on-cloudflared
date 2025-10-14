# bash_scripts
scripts to setup proxy on linux/windows, cloudflared tunnel urls are stored in [JSONBIN](https://github.com/waxz/json-bin)

- gost server/client over cloudflare tunnel, [proxy_gost_cf.sh](proxy_gost_cf.sh)
- v2ray server over cloudflare tunnel, [run_v2ray.sh](run_v2ray.sh)
- ssh/ttyd over cloudflare tunnel
- v2raya on windows
- tor on linux


## web

### ttyd
visit your jsonbin domain
```
https://<YOUR_JSONBIN_DOMAIN>/ttyd/aws/?key=<YOUR_JSONBINKEY>&redirect=1
```
## v2ray subscription
```
https://<YOUR_JSONBIN_DOMAIN>/v2ray/aws/?key=<YOUR_JSONBINKEY>&q=sub
```

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

### install cron jobs to start gost server

```bash
./install_proxy_gost_cf.sh
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
