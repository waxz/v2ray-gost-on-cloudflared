#!/bin/bash
set -e


V2_CONFIG_PATH="/usr/local/etc/v2ray/config.json"

# Choose mode: tor or direct
MODE="${1:-direct}"   # "tor" or "direct"

if [[ "$MODE" == "tor" ]]; then
  OUTBOUND=$(cat <<EOF
{
  "protocol": "socks",
  "settings": {
    "servers": [
      {
        "address": "127.0.0.1",
        "port": 9060
      }
    ]
  }
}
EOF
)
else
  OUTBOUND='{"protocol":"freedom","settings":{}}'
fi

# Update config.json
jq --argjson out "$OUTBOUND" '.outbounds[0]=$out' "$V2_CONFIG_PATH" > "${V2_CONFIG_PATH}.tmp" && mv "${V2_CONFIG_PATH}.tmp" "$V2_CONFIG_PATH"

# Restart V2Ray
systemctl restart v2ray
echo "✅ V2Ray restarted with outbound mode: $MODE. Check your ip at https://www.showmyip.com/"
