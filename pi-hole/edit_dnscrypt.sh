#!/bin/bash

if [ "$EUID" -ne 0 ]; then 
    echo "❌ Error: This script MUST be run with sudo!"
    echo "   Usage: sudo $0"
    exit 1
fi

FILE_PATH="/var/lib/docker/volumes/pi-hole_dnscrypt_config/_data/dnscrypt-proxy.toml"

echo "========================================="
echo "  DNSCrypt-Proxy Configuration Editor"
echo "========================================="
echo ""

if [ -f "$FILE_PATH" ]; then
    if [ ! -s "$FILE_PATH" ]; then
        echo "📝 File is empty. Adding message..."
        echo "salin konfigurasi dari dnscrypt-proxy.template.toml" > "$FILE_PATH"
        echo "✅ Message successfully added to file"
    else
        echo "✅ File already exists and is not empty"
    fi
else
    echo "📝 File not found. Creating new file..."
    echo "salin konfigurasi dari dnscrypt-proxy.template.toml" > "$FILE_PATH"
    echo "✅ New file created with message"
fi

echo ""
echo "📂 Opening file for editing..."
echo "========================================="
nano "$FILE_PATH"

echo ""
echo "✅ Done!"