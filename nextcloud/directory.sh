#!/bin/bash

CONFIG_PATH="/var/lib/docker/volumes/nextcloud_nextcloud_data/_data/config/config.php"
DATA_PATH="/var/lib/docker/volumes/nextcloud_nextcloud_data/_data/"

echo "=== Nextcloud Config Editor ==="
echo
echo "File config:"
echo "  $CONFIG_PATH"
echo

if [ ! -f "$CONFIG_PATH" ]; then
  echo "❌ config.php file not found!"
  exit 1
fi

read -p "Proceed to edit config.php with nano? (y/n): " confirm
if [[ "$confirm" != "y" ]]; then
  echo "Cancelled."
  exit 0
fi

sudo nano "$CONFIG_PATH"

echo
read -p "Switch to Nextcloud data directory now? (y/n): " cdconfirm
if [[ "$cdconfirm" == "y" ]]; then
  cd "$DATA_PATH" || exit
  echo "📂 Now in:"
  pwd
  exec "$SHELL"
fi

echo "Done."