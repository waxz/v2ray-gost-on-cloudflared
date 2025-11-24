#!/usr/bin/env bash
set -euo pipefail

# --- Dependency Import & Environment Setup ---
source /bin/bash_utils.sh
VARFILE="/opt/.vars"

# Extract all environment variables from the helper function
while IFS='=' read -r k v; do
    [ -z "$k" ] && continue
    export "$k=$v"
done < <(extract_all_env)

# Validate essential environment variables
for var in JSONBINKEY JSONBINURL JSONBINOPENLISTDATAPATH JSONBINOPENLISTPATH FILEN_EMAIL FILEN_PASSWORD; do
    if [ -z "${!var}" ]; then
        echo "❌ Error: $var is not set in $VARFILE."
        exit 1
    fi
done
# ------------------ Configuration ------------------
PORT=5244
FILEN_PORT=5255
CLOUDFLARED_LOG="/tmp/cloudflared-tunnel-$PORT.log"
OPENLIST_LOG="/tmp/openlist-$PORT.log"
FILEN_LOG="/tmp/filen-$FILEN_PORT.log"
WAIT_TIMEOUT=60

curl "$JSONBINURL/$JSONBINOPENLISTDATAPATH/?key=$JSONBINKEY" -o my_archive.tar.gz
mkdir -p /tmp/openlist_data
tar -xzvf my_archive.tar.gz -C /tmp/openlist_data
# openlist admin set "$JSONBINKEY" --data /tmp/openlist_data/data
nohup setsid bash -c "cd /tmp/openlist_data && openlist admin set "$JSONBINKEY" && openlist server" >"$OPENLIST_LOG" 2>&1 &

nohup setsid bash -c "filen webdav --email $FILEN_EMAIL --password $FILEN_PASSWORD --w-user $JSONBINKEY --w-password $JSONBINKEY --w-port $FILEN_PORT" > "$FILEN_LOG" 2>&1 &
sleep 3
# --- 2. Start Cloudflared Tunnel ---
echo "=== Starting cloudflared tunnel for OpenList and Filen ==="
/bin/setup_cftunnel.sh "$PORT"



# --- 6. Wait for Public URL ---
echo "Waiting up to $WAIT_TIMEOUT seconds for cloudflared public URL..."
PUBLIC_URL=""

PUBLIC_URL=$(grep -Eo 'https?://[A-Za-z0-9.-]+\.trycloudflare\.com' "$CLOUDFLARED_LOG" | head -n1 || true)

if [ -z "$PUBLIC_URL" ]; then
    echo "❌ Failed to detect public URL. Check log: $CLOUDFLARED_LOG"
    exit 1
fi

echo "✅ Detected public URL: $PUBLIC_URL"

# --- 8. Final Output & JSON Update ---
echo
echo "=== Setup complete ==="
echo "Expose Local:    127.0.0.1:$PORT"
echo "Public URL:    $PUBLIC_URL"
echo "Log File:      $CLOUDFLARED_LOG"
echo "Updating JSONBIN..."

curl -s "$JSONBINURL/$JSONBINOPENLISTPATH/?key=$JSONBINKEY&q=url" -d "$PUBLIC_URL"
echo "" # Newline for clean exit