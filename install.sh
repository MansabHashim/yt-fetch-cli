#!/bin/bash

# 1. Colors and Setup
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}Installing yt-fetch-cli...${NC}"

# 2. Dependency Check (Auto-Install)
OS_TYPE="$(uname)"
if [[ "$OS_TYPE" == "Linux" ]]; then
    sudo apt update && sudo apt install -y yt-dlp jq curl
elif [[ "$OS_TYPE" == "Darwin" ]]; then
    brew install yt-dlp jq
fi

# 3. Download the actual CLI logic
# We download it to a temporary location first
curl -sSL "https://raw.githubusercontent.com/mansabhashim/yt-fetch-cli/main/fetch-links.sh" -o yt-fetch-cli

# 4. Move to System Path
chmod +x yt-fetch-cli
sudo mv yt-fetch-cli /usr/local/bin/yt-fetch-cli

echo -e "${GREEN}Success! You can now run the command from anywhere.${NC}"
echo -e "Usage: ${BLUE}yt-fetch-cli${NC}"
