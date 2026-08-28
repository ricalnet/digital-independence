#!/bin/bash

echo "Editing Vaultwarden config.json..."
echo "Press ESC then :wq to save and exit, or :q! to exit without saving"
echo ""

docker compose exec vaultwarden vi /data/config.json
