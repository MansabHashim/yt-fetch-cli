#!/bin/bash

# Colors
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

# 1. Input Handling
read -p "Enter YouTube @username or URL: " USER_INPUT

if [[ $USER_INPUT == @* ]]; then
    FULL_URL="https://www.youtube.com/${USER_INPUT}/videos"
    HANDLE=$USER_INPUT
elif [[ $USER_INPUT == http* ]]; then
    FULL_URL=$USER_INPUT
    HANDLE=$(echo "$USER_INPUT" | grep -o '@[^/]*' || echo "@channel")
else
    FULL_URL="https://www.youtube.com/@${USER_INPUT}/videos"
    HANDLE="@${USER_INPUT}"
fi

FOLDER_NAME="$HOME/YouTube_Lists"
mkdir -p "$FOLDER_NAME"

# 2. Progress Bar
echo -ne "${YELLOW}🚀 Initializing... [          ] (0%)\r"
RAW_JSON=$(yt-dlp --quiet --flat-playlist --dump-single-json "$FULL_URL")
echo -ne "${YELLOW}🚀 Processing...   [========  ] (80%)\r"

if [ -z "$RAW_JSON" ]; then
    echo -e "${RED}\nError: Could not fetch data. Check the URL.${NC}"
    exit 1
fi

# 3. Stats Calculation (using jq)
VIDEO_COUNT=$(echo "$RAW_JSON" | jq '.entries | length')
TOTAL_VIEWS=$(echo "$RAW_JSON" | jq '[.entries[].view_count // 0] | add')
TOTAL_SEC=$(echo "$RAW_JSON" | jq '[.entries[].duration // 0] | add')
MIN_VIEWS=$(echo "$RAW_JSON" | jq '[.entries[].view_count // 0] | min')
MAX_VIEWS=$(echo "$RAW_JSON" | jq '[.entries[].view_count // 0] | max')
LATEST_URL=$(echo "$RAW_JSON" | jq -r '.entries[0].url // .entries[0].id')
OLDEST_URL=$(echo "$RAW_JSON" | jq -r '.entries[-1].url // .entries[-1].id')

TOTAL_TIME=$(printf '%dh:%dm:%ds\n' $((TOTAL_SEC/3600)) $((TOTAL_SEC%3600/60)) $((TOTAL_SEC%60)))

# Save Naked List
echo "$RAW_JSON" | jq -r '.entries[] | "https://www.youtube.com/watch?v=" + (.id // .url)' > "${FOLDER_NAME}/${HANDLE}-urls.txt"

echo -ne "${GREEN}🚀 Complete!        [==========] (100%)\r"
echo -e "\n"

# 4. Dashboard
echo -e "${BLUE}============================================================${NC}"
printf "${BOLD}${CYAN}  YT-FETCH-CLI OVERVIEW: %-30s ${NC}\n" "$HANDLE"
echo -e "${BLUE}============================================================${NC}"
printf "  Videos: %-10s | Views:  %'d\n" "$VIDEO_COUNT" "$TOTAL_VIEWS"
printf "  Length: %-10s | Avg:    %'d\n" "$TOTAL_TIME" "$((TOTAL_VIEWS/VIDEO_COUNT))"
echo -e "${BLUE}------------------------------------------------------------${NC}"
printf "${YELLOW}  MAX VIEWS: ${NC} %'d\n" "$MAX_VIEWS"
printf "${YELLOW}  MIN VIEWS: ${NC} %'d\n" "$MIN_VIEWS"
printf "${PURPLE}  LATEST:    ${NC} https://www.youtube.com/watch?v=%s\n" "$LATEST_URL"
printf "${PURPLE}  OLDEST:    ${NC} https://www.youtube.com/watch?v=%s\n" "$OLDEST_URL"
echo -e "${BLUE}============================================================${NC}\n"

# 5. Pure Link List for Copying
cat "${FOLDER_NAME}/${HANDLE}-urls.txt"
echo -e "\n${BLUE}============================================================${NC}"
echo -e "${GREEN}✔ Saved: ${FOLDER_NAME}/${HANDLE}-urls.txt${NC}\n"
