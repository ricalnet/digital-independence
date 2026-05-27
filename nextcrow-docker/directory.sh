#!/bin/bash

CONFIG_PATH="/var/lib/docker/volumes/nextcrow-docker_nextcrow_data/_data/config/config.php"
DATA_PATH="/var/lib/docker/volumes/nextcrow-docker_nextcrow_data/_data/"

echo "=== Nextcloud Config Editor ==="
echo
echo "File config:"
echo "  $CONFIG_PATH"
echo

if [ ! -f "$CONFIG_PATH" ]; then
  echo "❌ File config.php tidak ditemukan!"
  exit 1
fi

read -p "Lanjutkan edit config.php dengan nano? (y/n): " confirm
if [[ "$confirm" != "y" ]]; then
  echo "Dibatalkan."
  exit 0
fi

sudo nano "$CONFIG_PATH"

echo
read -p "Pindah ke direktori data NextCrow sekarang? (y/n): " cdconfirm
if [[ "$cdconfirm" == "y" ]]; then
  cd "$DATA_PATH" || exit
  echo "📂 Sekarang berada di:"
  pwd
  exec "$SHELL"
fi

echo "Selesai."