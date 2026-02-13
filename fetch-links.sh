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

if [ -z "$USER_INPUT" ]; then
    echo -e "${RED}Error: No input provided.${NC}"
    exit 1
fi

# Handle URL/Handle logic
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

# 2. Smooth Progress Bar Function (Background)
draw_progress() {
    local progress=0
    while [ $progress -lt 90 ]; do
        # If the data file exists, jump to 100% and break
        if [ -f /tmp/yt_data_ready ]; then break; fi
        
        # Gradually increase progress
        ((progress+=2))
        local filled=$((progress / 5))
        local empty=$((20 - filled))
        
        # Create bar string
        local bar=$(printf "%${filled}s" | tr ' ' '=')
        local spaces=$(printf "%${empty}s" | tr ' ' ' ')
        
        echo -ne "${YELLOW}🚀 Fetching Data: [${bar}${spaces}] (${progress}%)\r"
        sleep 0.1
    done
    
    # Final 100% state
    echo -ne "${GREEN}🚀 Data Ready!    [====================] (100%)\r"
    echo -e "\n"
}

# Clear old flags
rm -f /tmp/yt_data_ready

# Start animation in background
draw_progress &
ANIM_PID=$!

# 3. Actual Data Fetching
RAW_JSON=$(yt-dlp --quiet --flat-playlist --dump-single-json "$FULL_URL")

# Kill animation and set flag for 100%
touch /tmp/yt_data_ready
wait $ANIM_PID
rm -f /tmp/yt_data_ready

if [ -z "$RAW_JSON" ]; then
    echo -e "${RED}Error: Could not fetch data. Check your connection or handle.${NC}"
    exit 1
fi

# 4. Stats Calculation
VIDEO_COUNT=$(echo "$RAW_JSON" | jq '.entries | length')
TOTAL_VIEWS=$(echo "$RAW_JSON" | jq '[.entries[].view_count // 0] | add')
TOTAL_SEC=$(echo "$RAW_JSON" | jq '[.entries[].duration // 0] | add')
MIN_VIEWS=$(echo "$RAW_JSON" | jq '[.entries[].view_count // 0] | min')
MAX_VIEWS=$(echo "$RAW_JSON" | jq '[.entries[].view_count // 0] | max')
LATEST_URL=$(echo "$RAW_JSON" | jq -r '.entries[0].url // .entries[0].id')
OLDEST_URL=$(echo "$RAW_JSON" | jq -r '.entries[-1].url // .entries[-1].id')

TOTAL_TIME=$(printf '%dh:%dm:%ds\n' $((TOTAL_SEC/3600)) $((TOTAL_SEC%3600/60)) $((TOTAL_SEC%60)))
AVG_VIEWS=$((VIDEO_COUNT > 0 ? TOTAL_VIEWS / VIDEO_COUNT : 0))

# Determine if URL is a playlist and set appropriate filename
if [[ $FULL_URL == *"list="* ]]; then
    # Extract playlist title and channel name from JSON
    PLAYLIST_TITLE=$(echo "$RAW_JSON" | jq -r '.title // "Playlist"')
    CHANNEL_NAME=$(echo "$RAW_JSON" | jq -r '.channel // .uploader // "Unknown"')
    
    # Sanitize names for filename (replace special characters)
    PLAYLIST_TITLE=$(echo "$PLAYLIST_TITLE" | tr -cd '[:alnum:] -' | tr ' ' '_' | sed 's/^[_-]*//;s/[_-]*$//')
    CHANNEL_NAME=$(echo "$CHANNEL_NAME" | tr -cd '[:alnum:] -' | tr ' ' '_' | sed 's/^[_-]*//;s/[_-]*$//')
    
    # Fallback to defaults if sanitization results in empty strings
    PLAYLIST_TITLE=${PLAYLIST_TITLE:-"Playlist"}
    CHANNEL_NAME=${CHANNEL_NAME:-"Unknown"}
    
    # Truncate to prevent filesystem path length issues (max 100 chars each)
    PLAYLIST_TITLE=${PLAYLIST_TITLE:0:100}
    CHANNEL_NAME=${CHANNEL_NAME:0:100}
    
    FILE_PATH="${FOLDER_NAME}/${PLAYLIST_TITLE}_by_${CHANNEL_NAME}.txt"
else
    # Use handle for channel videos (existing behavior)
    FILE_PATH="${FOLDER_NAME}/${HANDLE}-urls.txt"
fi
echo "$RAW_JSON" | jq -r '.entries[] | "https://www.youtube.com/watch?v=" + (.id // .url)' > "$FILE_PATH"

# 5. Dashboard (Always Displayed)
echo -e "${BLUE}============================================================${NC}"
printf "${BOLD}${CYAN}  YT-FETCH-CLI OVERVIEW: %-30s ${NC}\n" "$HANDLE"
echo -e "${BLUE}============================================================${NC}"
printf "  Videos: %-10s | Views:  %'d\n" "$VIDEO_COUNT" "$TOTAL_VIEWS"
printf "  Length: %-10s | Avg:    %'d\n" "$TOTAL_TIME" "$AVG_VIEWS"
echo -e "${BLUE}------------------------------------------------------------${NC}"
printf "${YELLOW}  MAX VIEWS: ${NC} %'d\n" "$MAX_VIEWS"
printf "${YELLOW}  MIN VIEWS: ${NC} %'d\n" "$MIN_VIEWS"
printf "${PURPLE}  LATEST:    ${NC} https://www.youtube.com/watch?v=%s\n" "$LATEST_URL"
printf "${PURPLE}  OLDEST:    ${NC} https://www.youtube.com/watch?v=%s\n" "$OLDEST_URL"
echo -e "${BLUE}============================================================${NC}"

# 6. Ask User for URLs
echo -e "\n"
read -p "Would you like to display the raw URLs? (y/n): " SHOW_URLS

if [[ "$SHOW_URLS" == "y" || "$SHOW_URLS" == "Y" ]]; then
    echo -e "\n${BOLD}${YELLOW}RAW URL LIST:${NC}"
    cat "$FILE_PATH"
    echo -e "${BLUE}============================================================${NC}"
fi

echo -e "${GREEN}✔ Results saved to: $FILE_PATH${NC}\n"
