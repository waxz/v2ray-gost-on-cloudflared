#!/bin/bash

# Define a host to ping for network connectivity check
PING_HOST="8.8.8.8" # Google's public DNS server

# Ping the host and check for success
ping -c 3 -W 2 "$PING_HOST" > /dev/null 2>&1

# Check the exit status of the ping command
if [ $? -ne 0 ]; then
    # Ping failed, network connection is down
    echo "Network connection failed. Initiating reboot..."
    sudo reboot now
else
    echo "Network connection is active."
fi