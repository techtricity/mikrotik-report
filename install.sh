#!/bin/bash

# Configuration
SCRIPT_NAME="mikrotik-report.sh"
CONF_NAME="mikrotik-report.conf"
DEST_DIR="/usr/local/bin"
CONF_DIR="/etc"

echo "--- Mikrotik Reporter Installer ---"

# 1. Check for root privileges
if [[ $EUID -ne 0 ]]; then
   echo "Error: This script must be run as root (use sudo)."
   exit 1
fi

# 2. Copy the main script
if [ -f "./$SCRIPT_NAME" ]; then
    echo "Installing $SCRIPT_NAME to $DEST_DIR..."
    cp "./$SCRIPT_NAME" "$DEST_DIR/"
    chmod +x "$DEST_DIR/$SCRIPT_NAME"
    echo "Successfully installed $SCRIPT_NAME."
else
    echo "Error: $SCRIPT_NAME not found in current directory."
    exit 1
fi

# 3. Handle Configuration File
if [ ! -f "$CONF_DIR/$CONF_NAME" ]; then
    if [ -f "./$CONF_NAME" ]; then
        echo "No system-wide config found. Copying local $CONF_NAME to $CONF_DIR..."
        cp "./$CONF_NAME" "$CONF_DIR/"
        chmod 600 "$CONF_DIR/$CONF_NAME" # Secure it since it contains emails
        echo "Config installed to $CONF_DIR."
    else
        echo "Warning: No $CONF_NAME found locally or in $CONF_DIR."
        echo "Please create $CONF_DIR/$CONF_NAME manually."
    fi
else
    echo "System-wide config already exists at $CONF_DIR/$CONF_NAME. Skipping copy."
fi

# 4. Check for Dependencies
echo "Checking dependencies..."
for cmd in mmdblookup whois mailx; do
    if ! command -v $cmd &> /dev/null; then
        echo "Warning: '$cmd' is not installed. You may need: sudo apt install whois mmdb-bin mailutils"
    fi
done

echo "--- Installation Complete ---"
