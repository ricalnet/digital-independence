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

echo -e "${YELLOW}Mulai proses penyalinan file ke container yourls-yourls-1...${NC}"
echo "==================================="

docker ps | grep yourls-yourls-1 > /dev/null
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Container yourls-yourls-1 tidak ditemukan atau tidak running${NC}"
    exit 1
fi

echo "Menyalin index.php..."
docker cp Sleeky/sleeky-frontend/index.php yourls-yourls-1:/var/www/html/
check_error "Menyalin index.php"

echo "Menyalin folder frontend..."
docker cp Sleeky/sleeky-frontend/frontend/ yourls-yourls-1:/var/www/html/
check_error "Menyalin folder frontend"

echo "==================================="
echo -e "${YELLOW}Merestart container yourls-yourls-1...${NC}"
docker container restart yourls-yourls-1
check_error "Merestart container"

echo "==================================="
echo -e "${GREEN}✅ Semua proses selesai! Container telah direstart.${NC}"
