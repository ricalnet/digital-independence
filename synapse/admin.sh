#!/usr/bin/env bash

set -euo pipefail

if ! command -v jq &> /dev/null; then
    echo "Error: 'jq' is not installed. Please install it with: sudo apt install jq"
    exit 1
fi

echo "=========================================="
echo "   COMPLETE SYNAPSE ADMIN TOOLKIT"
echo "=========================================="

read -rp "Enter Homeserver Domain [e.g., matrix.domain.com]: " DOMAIN
read -rs -p "Enter Admin Access Token: " ADMIN_TOKEN
echo ""

BASE_URL="https://${DOMAIN}/_synapse/admin"

urlencode() {
    jq -rn --arg x "$1" '$x|@uri'
}

make_req() {
    local method="$1"
    local path="$2"
    local data="${3:-}"

    if [ -n "$data" ]; then
        curl -s -X "$method" \
            -H "Authorization: Bearer ${ADMIN_TOKEN}" \
            -H "Content-Type: application/json" \
            -d "$data" \
            "${BASE_URL}${path}"
    else
        curl -s -X "$method" \
            -H "Authorization: Bearer ${ADMIN_TOKEN}" \
            -H "Content-Type: application/json" \
            "${BASE_URL}${path}"
    fi
}

get_server_info() {
    echo -e "\n--- SERVER INFORMATION & VERSION ---"
    make_req "GET" "/v1/server_version" | jq .
}

list_all_users() {
    echo -e "\n--- ALL USERS (FULL LIST) ---"
    make_req "GET" "/v2/users?limit=500" | jq -r '.users[] | "ID: \(.name) | Name: \(.displayname // "-") | Admin: \(.admin) | Deactivated: \(.deactivated) | ShadowBanned: \(.shadow_banned // false)"'
}

list_admins() {
    echo -e "\n--- ADMINISTRATOR LIST ---"
    make_req "GET" "/v2/users?limit=500" | jq -r '.users[] | select(.admin == true or .admin == 1) | "ID: \(.name) | Name: \(.displayname // "-")"'
}

get_user_details() {
    read -rp "Enter User ID [@user:domain.com]: " TARGET_USER
    local ENC_USER
    ENC_USER=$(urlencode "$TARGET_USER")
    echo -e "\n--- USER DETAILS FOR ${TARGET_USER} ---"
    make_req "GET" "/v2/users/${ENC_USER}" | jq .
}

create_new_user() {
    read -rp "Enter New Username [without @ and domain]: " USERNAME
    read -rs -p "Enter New Password: " PASSWORD
    echo ""
    read -rp "Enter Display Name: " DISPLAYNAME
    read -rp "Make Admin? (y/N): " IS_ADMIN_INPUT

    local IS_ADMIN=false
    if [[ "$IS_ADMIN_INPUT" =~ ^[Yy]$ ]]; then
        IS_ADMIN=true
    fi

    local FULL_USER_ID="@${USERNAME}:${DOMAIN}"
    local ENC_USER
    ENC_USER=$(urlencode "$FULL_USER_ID")

    local PAYLOAD
    PAYLOAD=$(jq -n \
        --arg pwd "$PASSWORD" \
        --arg name "$DISPLAYNAME" \
        --argjson adm "$IS_ADMIN" \
        '{password: $pwd, displayname: $name, admin: $adm, deactivated: false}')

    echo "Creating user ${FULL_USER_ID}..."
    make_req "PUT" "/v2/users/${ENC_USER}" "$PAYLOAD" | jq .
}

promote_user() {
    read -rp "Enter User ID [@user:domain.com]: " TARGET_USER
    local ENC_USER
    ENC_USER=$(urlencode "$TARGET_USER")
    echo "Promoting ${TARGET_USER} to Admin..."
    make_req "PUT" "/v2/users/${ENC_USER}" '{"admin": true}' | jq .
}

demote_user() {
    read -rp "Enter User ID [@user:domain.com]: " TARGET_USER
    local ENC_USER
    ENC_USER=$(urlencode "$TARGET_USER")
    echo "Demoting ${TARGET_USER} from Admin..."
    make_req "PUT" "/v2/users/${ENC_USER}" '{"admin": false}' | jq .
}

reset_password() {
    read -rp "Enter User ID [@user:domain.com]: " TARGET_USER
    local ENC_USER
    ENC_USER=$(urlencode "$TARGET_USER")
    read -rs -p "Enter New Password: " NEW_PASS
    echo ""
    local PAYLOAD
    PAYLOAD=$(jq -n --arg pwd "$NEW_PASS" '{new_password: $pwd, logout_devices: true}')
    echo "Changing password and logging out all sessions for ${TARGET_USER}..."
    make_req "POST" "/v2/users/${ENC_USER}/password" "$PAYLOAD" | jq .
}

manage_devices() {
    read -rp "Enter User ID [@user:domain.com]: " TARGET_USER
    local ENC_USER
    ENC_USER=$(urlencode "$TARGET_USER")
    echo -e "\n--- DEVICES / SESSIONS FOR ${TARGET_USER} ---"
    make_req "GET" "/v2/users/${ENC_USER}/devices" | jq -r '.devices[]? | "Device ID: \(.device_id) | Name: \(.display_name // "-") | IP: \(.last_seen_ip // "-")"'

    read -rp "Delete a specific device? (y/N): " DEL_CHOICE
    if [[ "$DEL_CHOICE" =~ ^[Yy]$ ]]; then
        read -rp "Enter Device ID to delete: " DEV_ID
        make_req "DELETE" "/v2/users/${ENC_USER}/devices/${DEV_ID}" | jq .
    fi
}

view_user_rooms() {
    read -rp "Enter User ID [@user:domain.com]: " TARGET_USER
    local ENC_USER
    ENC_USER=$(urlencode "$TARGET_USER")
    echo -e "\n--- ROOMS JOINED BY ${TARGET_USER} ---"
    make_req "GET" "/v1/users/${ENC_USER}/joined_rooms" | jq .
}

toggle_shadow_ban() {
    read -rp "Enter User ID [@user:domain.com]: " TARGET_USER
    local ENC_USER
    ENC_USER=$(urlencode "$TARGET_USER")
    read -rp "Enable Shadow Ban? (y/N = Disable): " SB_CHOICE

    local SB_VAL=false
    if [[ "$SB_CHOICE" =~ ^[Yy]$ ]]; then
        SB_VAL=true
    fi

    local PAYLOAD
    PAYLOAD=$(jq -n --argjson sb "$SB_VAL" '{shadow_banned: $sb}')
    echo "Updating Shadow Ban status..."
    make_req "PUT" "/v2/users/${ENC_USER}" "$PAYLOAD" | jq .
}

reactivate_user() {
    read -rp "Enter User ID [@user:domain.com]: " TARGET_USER
    local ENC_USER
    ENC_USER=$(urlencode "$TARGET_USER")
    echo "Reactivating account ${TARGET_USER}..."
    make_req "PUT" "/v2/users/${ENC_USER}" '{"deactivated": false}' | jq .
}

deactivate_user() {
    read -rp "Enter User ID [@user:domain.com]: " TARGET_USER
    local ENC_USER
    ENC_USER=$(urlencode "$TARGET_USER")
    read -rp "Delete all user data (GDPR Erase)? (y/N): " ERASE_CHOICE

    local ERASE_VAL=false
    if [[ "$ERASE_CHOICE" =~ ^[Yy]$ ]]; then
        ERASE_VAL=true
    fi

    read -rp "Are you sure you want to deactivate ${TARGET_USER}? (y/N): " CONFIRM
    if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
        local PAYLOAD
        PAYLOAD=$(jq -n --argjson er "$ERASE_VAL" '{erase: $er}')
        echo "Deactivating account ${TARGET_USER}..."
        make_req "POST" "/v2/users/${ENC_USER}/deactivate" "$PAYLOAD" | jq .
    else
        echo "Canceled."
    fi
}

list_all_rooms() {
    echo -e "\n--- SERVER ROOMS LIST ---"
    make_req "GET" "/v1/rooms?limit=500" | jq -r '.rooms[] | "Room ID: \(.room_id) | Name: \(.name // "-") | Members: \(.joined_members) | Encrypted: \(.encryption // "No")"'
}

get_room_details() {
    read -rp "Enter Room ID [!roomId:domain.com]: " ROOM_ID
    local ENC_ROOM
    ENC_ROOM=$(urlencode "$ROOM_ID")
    echo -e "\n--- ROOM DETAILS FOR ${ROOM_ID} ---"
    make_req "GET" "/v1/rooms/${ENC_ROOM}" | jq .
}

join_room_takeover() {
    read -rp "Enter Room ID or Alias [!roomId:domain.com or #alias:domain.com]: " ROOM_TARGET
    read -rp "Enter Admin User ID to join [@admin:domain.com]: " ADMIN_USER
    local ENC_ROOM
    ENC_ROOM=$(urlencode "$ROOM_TARGET")
    local PAYLOAD
    PAYLOAD=$(jq -n --arg u "$ADMIN_USER" '{user_id: $u}')
    echo "Joining ${ADMIN_USER} into ${ROOM_TARGET}..."
    make_req "POST" "/v1/join/${ENC_ROOM}" "$PAYLOAD" | jq .
}

delete_room() {
    read -rp "Enter Room ID [!roomId:domain.com]: " ROOM_ID
    local ENC_ROOM
    ENC_ROOM=$(urlencode "$ROOM_ID")
    read -rp "Are you sure you want to purge this room? (y/N): " CONFIRM
    if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
        local PAYLOAD
        PAYLOAD='{"block": true, "purge": true}'
        echo "Purging room ${ROOM_ID}..."
        make_req "POST" "/v1/rooms/${ENC_ROOM}/delete" "$PAYLOAD" | jq .
    else
        echo "Canceled."
    fi
}

purge_remote_media() {
    read -rp "Purge remote media older than how many days? [e.g., 30]: " DAYS
    local NOW_SEC
    NOW_SEC=$(date +%s)
    local BEFORE_SEC=$((NOW_SEC - (DAYS * 86400)))
    local BEFORE_MS=$((BEFORE_SEC * 1000))

    echo "Purging remote media cache..."
    make_req "POST" "/v1/purge_media_cache?before_ts=${BEFORE_MS}" | jq .
}

while true; do
    echo -e "\n=========================================="
    echo " SYNAPSE ADMIN API MANAGEMENT MENU"
    echo "=========================================="
    echo " [ SERVER INFORMATION ]"
    echo " 1. Server Information & Version"
    echo ""
    echo " [ USER MANAGEMENT ]"
    echo " 2. View All Users"
    echo " 3. View Admins Only"
    echo " 4. View User Details"
    echo " 5. Create New User"
    echo " 6. Promote User to Admin"
    echo " 7. Demote User from Admin"
    echo " 8. Reset Password (+ Force Logout)"
    echo " 9. Manage Devices / Login Sessions"
    echo " 10. View Joined Rooms by User"
    echo " 11. Toggle User Shadow Ban"
    echo " 12. Reactivate Account"
    echo " 13. Deactivate Account"
    echo ""
    echo " [ ROOM MANAGEMENT ]"
    echo " 14. View All Server Rooms"
    echo " 15. View Room Details"
    echo " 16. Force Join Room (Takeover)"
    echo " 17. Purge / Delete Room"
    echo ""
    echo " [ MAINTENANCE & MEDIA ]"
    echo " 18. Purge Remote Media Cache (By Days)"
    echo ""
    echo " 0. Exit"
    echo "=========================================="
    read -rp "Select an option [0-18]: " CHOICE

    case $CHOICE in
        1) get_server_info ;;
        2) list_all_users ;;
        3) list_admins ;;
        4) get_user_details ;;
        5) create_new_user ;;
        6) promote_user ;;
        7) demote_user ;;
        8) reset_password ;;
        9) manage_devices ;;
        10) view_user_rooms ;;
        11) toggle_shadow_ban ;;
        12) reactivate_user ;;
        13) deactivate_user ;;
        14) list_all_rooms ;;
        15) get_room_details ;;
        16) join_room_takeover ;;
        17) delete_room ;;
        18) purge_remote_media ;;
        0) echo "Done."; exit 0 ;;
        *) echo "Invalid choice!" ;;
    esac
done
