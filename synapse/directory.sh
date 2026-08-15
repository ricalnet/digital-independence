#!/bin/bash

CONFIG_PATH="/var/lib/docker/volumes/synapse_synapse_data/_data/homeserver.yaml"
DATA_PATH="/var/lib/docker/volumes/synapse_synapse_data/_data/"

echo "=== Synapse Config Editor ==="
echo
echo "Config file:"
echo "  $CONFIG_PATH"
echo

if [ ! -f "$CONFIG_PATH" ]; then
  echo "❌ File homeserver.yaml not found!"
  exit 1
fi

read -p "Continue editing homeserver.yaml with nano? (y/n): " confirm
if [[ "$confirm" != "y" ]]; then
  echo "Cancelled."
  exit 0
fi

sudo nano "$CONFIG_PATH"

echo
read -p "Switch to the Synapse data directory now? (y/n): " cdconfirm
if [[ "$cdconfirm" == "y" ]]; then
  cd "$DATA_PATH" || exit
  echo "📂 Now in:"
  pwd
  exec "$SHELL"
fi

echo "Done."