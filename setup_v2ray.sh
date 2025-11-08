#!/usr/bin/env bash
set -euo pipefail

source /bin/bash_utils.sh
BASHRC="/home/codespace/.bashrc"

# ✅ assign all extracted variables into the shell
while IFS='=' read -r k v; do
    # skip empty lines
    [ -z "$k" ] && continue
    export "$k=$v"
done < <(extract_all_env)



  if [ -z "$JSONBINKEY" ]; then
    echo "JSONBINKEY environment variable is not set in .bashrc."
    exit 1
  fi
  if [ -z "$JSONBINURL" ]; then
    echo "JSONBINURL environment variable is not set in .bashrc."
    exit 1
  fi
  if [ -z "$JSONBINV2RAYPATH" ]; then
    echo "JSONBINV2RAYPATH environment variable is not set in .bashrc."
    exit 1
  fi
  

# ------------------ Configurable ------------------
PORT=10000
WS_PATH="/ray"
SUB_JSON_PATH="/tmp/sub.json"
SUB_VMESS_PATH="/tmp/sub_vmess.txt"
V2_CONFIG_PATH="/usr/local/etc/v2ray/config.json"
V2_LOG_DIR="/var/log/v2ray"
V2RAY_LOG="/tmp/v2ray.log"
CLOUDFLARED_LOG="/tmp/cloudflared-tunnel.log"
CLOUDFLARED_PID_FILE="/var/run/cloudflared-tunnel.pid"
WAIT_TIMEOUT=60
# --------------------------------------------------

# --- 0. Sudo/root check ---
if [ "$EUID" -ne 0 ]; then
    echo "❌ Please run this script with sudo or as root"
    exit 1
fi

echo "=== 1. Checking existing installations ==="
V2_INSTALLED=false
if command -v v2ray >/dev/null 2>&1; then
  echo "V2Ray is already installed."
  V2_INSTALLED=true
fi

if ! command -v cloudflared >/dev/null 2>&1; then
  echo "❌ cloudflared not found. Install it before running this script."
  exit 1
else
  echo "cloudflared is installed."
fi

echo "=== 2. Kill existing processes using port $PORT ==="

kill_program "cloudflared tunnel --url localhost:$PORT"
kill_program "v2ray run -c $V2_CONFIG_PATH"


# --- 3. Install V2Ray if missing ---
if [ "$V2_INSTALLED" = false ]; then
  echo "=== Installing dependencies (curl, jq, uuid-runtime) ==="
  apt update -y
  apt install -y curl jq uuid-runtime || true

  echo "=== Installing V2Ray (fhs installer) ==="
  bash <(curl -L https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh)
fi

# --- 4. Generate UUID ---
UUID=$(uuidgen)
echo "V2Ray UUID: $UUID"

# --- 5. Prepare log directory and permissions ---
echo "=== Preparing V2Ray log directory ==="
mkdir -p "$V2_LOG_DIR"
V2_USER=$(grep '^User=' /etc/systemd/system/v2ray.service 2>/dev/null | cut -d= -f2 || echo "nobody")
V2_GROUP=$(grep '^Group=' /etc/systemd/system/v2ray.service 2>/dev/null | cut -d= -f2 || echo "nogroup")

chown -R "$V2_USER:$V2_GROUP" "$V2_LOG_DIR"
chmod 755 "$V2_LOG_DIR"

for logf in access.log error.log; do
    touch "$V2_LOG_DIR/$logf" 2>/dev/null || true
    chown "$V2_USER:$V2_GROUP" "$V2_LOG_DIR/$logf"
    chmod 644 "$V2_LOG_DIR/$logf"
done

# --- 6. Write V2Ray server config ---
echo "=== Writing V2Ray server config ==="
mkdir -p "$(dirname "$V2_CONFIG_PATH")"
cat >"$V2_CONFIG_PATH" <<EOF
{
  "inbounds": [
    {
      "port": $PORT,
      "listen": "127.0.0.1",
      "protocol": "vmess",
      "settings": {
        "clients": [
          {
            "id": "$UUID",
            "alterId": 0,
            "security": "auto"
          }
        ]
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "$WS_PATH",
          "headers": {
            "Host": ""
          }
        }
      }
    }
  ],
  "outbounds": [
    { "protocol": "freedom", "settings": {} }
  ],
  "log": {
    "access": "$V2_LOG_DIR/access.log",
    "error": "$V2_LOG_DIR/error.log",
    "loglevel": "warning"
  }
}
EOF

# --- 7. Enable & restart V2Ray ---
# systemctl enable v2ray || true
# systemctl restart v2ray

nohup setsid v2ray run -c $V2_CONFIG_PATH >"$V2RAY_LOG" 2>&1 &

sleep 1
if ss -ltnp | grep -q ":$PORT\\b"; then
  echo "✅ V2Ray is listening on 127.0.0.1:$PORT"
else
  echo "❌ V2Ray is NOT listening on $PORT. Check 'journalctl -u v2ray -n 50'"
  exit 1
fi

# --- 8. Start cloudflared tunnel ---
echo "=== Starting cloudflared tunnel ==="
mkdir -p "$(dirname "$CLOUDFLARED_LOG")"
: > "$CLOUDFLARED_LOG"

nohup setsid cloudflared tunnel --url "localhost:$PORT" >"$CLOUDFLARED_LOG" 2>&1 &
CLOUDFLARED_PID=$!
echo "$CLOUDFLARED_PID" > "$CLOUDFLARED_PID_FILE"
sleep 0.5

# --- Wait for public URL ---
echo "Waiting up to $WAIT_TIMEOUT seconds for cloudflared public URL..."
END_TIME=$(( $(date +%s) + WAIT_TIMEOUT ))
PUBLIC_URL=""
while [ "$(date +%s)" -le "$END_TIME" ]; do
  PUBLIC_URL=$(grep -Eo 'https?://[A-Za-z0-9.-]+\.trycloudflare\.com' "$CLOUDFLARED_LOG" | head -n1 || true)
  if [ -n "$PUBLIC_URL" ]; then break; fi
  sleep 1
done

if [ -z "$PUBLIC_URL" ]; then
  echo "❌ Failed to detect public URL. See $CLOUDFLARED_LOG"
  exit 1
fi
echo "✅ Detected public URL: $PUBLIC_URL"
PUBLIC_HOST=$(echo "$PUBLIC_URL" | sed -E 's#^https?://([^/:]+).*#\1#')

# Update V2Ray Host header
jq --arg host "$PUBLIC_HOST" '.inbounds[0].streamSettings.wsSettings.headers.Host = $host' "$V2_CONFIG_PATH" >"${V2_CONFIG_PATH}.tmp" && mv "${V2_CONFIG_PATH}.tmp" "$V2_CONFIG_PATH"
systemctl restart v2ray

# --- 9. Generate plain JSON subscription ---
cat >"$SUB_JSON_PATH" <<EOF
[
  {
    "v": "2",
    "ps": "Cloudflared-Tunnel",
    "add": "$PUBLIC_HOST",
    "port": "443",
    "id": "$UUID",
    "aid": "0",
    "net": "ws",
    "type": "none",
    "host": "$PUBLIC_HOST",
    "path": "$WS_PATH",
    "tls": "tls"
  }
]
EOF

# --- 10. Generate vmess:// subscription ---
NODE_JSON=$(jq -n \
  --arg v "2" \
  --arg ps "Cloudflared-Tunnel" \
  --arg add "$PUBLIC_HOST" \
  --arg port "443" \
  --arg id "$UUID" \
  --arg aid "0" \
  --arg net "ws" \
  --arg type "none" \
  --arg host "$PUBLIC_HOST" \
  --arg path "$WS_PATH" \
  --arg tls "tls" \
  '{v:$v,ps:$ps,add:$add,port:$port,id:$id,aid:$aid,net:$net,type:$type,host:$host,path:$path,tls:$tls}'
)
B64=$(echo -n "$NODE_JSON" | base64 -w0)
echo "vmess://$B64" > "$SUB_VMESS_PATH"

# --- 11. Self-check cloudflared connectivity ---
echo "=== Checking cloudflared tunnel connectivity ==="
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$PUBLIC_URL" || true)
if [[ "$HTTP_CODE" =~ ^2|3|4 ]]; then
  echo "✅ Cloudflared tunnel is reachable: HTTP $HTTP_CODE"
else
  echo "⚠️ Cloudflared tunnel may not be reachable (HTTP $HTTP_CODE)."
fi

# --- Done ---
echo
echo "=== Setup complete ==="
echo "V2Ray: 127.0.0.1:$PORT (ws path: $WS_PATH)"
echo "UUID: $UUID"
echo "Tunnel URL: $PUBLIC_URL"
echo "Plain JSON subscription: $SUB_JSON_PATH"
echo "vmess subscription: $SUB_VMESS_PATH"
echo "cloudflared log: $CLOUDFLARED_LOG"
cat $CLOUDFLARED_LOG
cat $SUB_JSON_PATH
cat $SUB_VMESS_PATH
curl "$JSONBINURL/$JSONBINV2RAYPATH/?key=$JSONBINKEY&q=sub" -d @$SUB_VMESS_PATH