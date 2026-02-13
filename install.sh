#!/bin/bash

# Colors for professional output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}Starting yt-fetch-cli installation...${NC}"

# 1. Detect OS and Install Dependencies
OS_TYPE="$(uname)"

case "$OS_TYPE" in
    "Linux")
        echo "Detected Linux. Installing dependencies via apt..."
        sudo apt update && sudo apt install -y yt-dlp jq curl
        ;;
    "Darwin")
        echo "Detected macOS. Installing dependencies via Homebrew..."
        if ! command -v brew &> /dev/null; then
            echo -e "${RED}Homebrew not found. Please install it first at https://brew.sh${NC}"
            exit 1
        fi
        brew install yt-dlp jq
        ;;
    "MINGW"*|"MSYS"*|"CYGWIN"*)
        echo "Detected Windows (Git Bash/MSYS). Checking dependencies..."
        echo "Please ensure yt-dlp and jq are in your PATH."
        ;;
    *)
        echo -e "${RED}Unsupported OS: $OS_TYPE${NC}"
        exit 1
        ;;
esac

# 2. Download the main script
SCRIPT_URL="https://raw.githubusercontent.com/mansab/yt-fetch-cli/main/fetch-links.sh"
DESTINATION="/usr/local/bin/fetch-links"

echo -e "${BLUE}Downloading script...${NC}"
curl -sSL "$SCRIPT_URL" -o fetch-links

# 3. Move to Bin and make executable
chmod +x fetch-links
if [[ "$OS_TYPE" == "MINGW"* ]]; then
    # Windows/Git Bash usually doesn't need sudo for local bin
    mv fetch-links /usr/bin/fetch-links
else
    sudo mv fetch-links "$DESTINATION"
fi

echo -e "${GREEN}Installation Complete!${NC}"
echo -e "Try it now by typing: ${BLUE}fetch-links${NC}"
