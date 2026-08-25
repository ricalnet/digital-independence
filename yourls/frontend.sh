#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

check_error() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ $1 berhasil${NC}"
    else
        echo -e "${RED}❌ $1 gagal${NC}"
        exit 1
    fi
}

echo -e "${YELLOW}Mulai proses penyalinan file ke container yourls-fpm...${NC}"
echo "==================================="

docker ps | grep yourls-fpm > /dev/null
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Container yourls-fpm tidak ditemukan atau tidak running${NC}"
    exit 1
fi

echo "Menyalin index.php..."
docker cp /home/rpi/digital-independence/yourls/Sleeky/sleeky-frontend/index.php yourls-fpm:/var/www/html/
check_error "Menyalin index.php"

echo "Menyalin folder frontend..."
docker cp /home/rpi/digital-independence/yourls/Sleeky/sleeky-frontend/frontend/ yourls-fpm:/var/www/html/
check_error "Menyalin folder frontend"

echo "==================================="
echo -e "${YELLOW}Merestart container yourls-fpm...${NC}"
docker container restart yourls-fpm
check_error "Merestart container"

echo "==================================="
echo -e "${GREEN}✅ Semua proses selesai! Container telah direstart.${NC}"
