#!/bin/bash

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Installing yt-fetch-cli...${NC}"

# Detect OS and Install Dependencies
OS_TYPE="$(uname)"
if [[ "$OS_TYPE" == "Linux" ]]; then
    sudo apt update && sudo apt install -y yt-dlp jq curl
elif [[ "$OS_TYPE" == "Darwin" ]]; then
    brew install yt-dlp jq
fi

# Download the actual CLI logic from YOUR repo
curl -sSL "https://raw.githubusercontent.com/mansabhashim/yt-fetch-cli/main/fetch-links.sh" -o yt-fetch-cli

# Move to System Path
chmod +x yt-fetch-cli
sudo mv yt-fetch-cli /usr/local/bin/yt-fetch-cli

echo -e "${GREEN}Success! Installation Complete.${NC}"
echo -e "Type ${BLUE}yt-fetch-cli${NC} to run it."
