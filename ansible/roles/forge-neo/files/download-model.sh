#!/bin/bash
# Model Download Helper for Stable Diffusion Forge Neo
# Supports downloading from HuggingFace and Civitai

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FORGE_DIR="$SCRIPT_DIR"
MODELS_DIR="$FORGE_DIR/models/Stable-diffusion"
LORA_DIR="$FORGE_DIR/models/Lora"
VAE_DIR="$FORGE_DIR/models/VAE"

echo -e "${GREEN}=== Stable Diffusion Model Downloader ===${NC}\n"

# Activate virtual environment if it exists
if [ -f "$FORGE_DIR/venv/bin/activate" ]; then
    source "$FORGE_DIR/venv/bin/activate"
fi

show_usage() {
    echo "Usage: $0 <source> <url> [destination]"
    echo ""
    echo "Sources:"
    echo "  hf       - HuggingFace model repository"
    echo "  civitai  - Civitai model download"
    echo ""
    echo "Examples:"
    echo "  # Download from HuggingFace"
    echo "  $0 hf runwayml/stable-diffusion-v1-5"
    echo "  $0 hf stabilityai/stable-diffusion-xl-base-1.0"
    echo ""
    echo "  # Download from Civitai"
    echo "  $0 civitai https://civitai.com/api/download/models/XXXXX"
    echo "  $0 civitai <model-id>"
    echo ""
    echo "Destination (optional):"
    echo "  sd    - Stable Diffusion checkpoints (default)"
    echo "  lora  - LoRA models"
    echo "  vae   - VAE models"
}

download_from_huggingface() {
    local repo=$1
    local dest_dir=$2

    echo -e "${YELLOW}Downloading from HuggingFace: $repo${NC}"

    # Use huggingface-cli to download
    if command -v huggingface-cli &> /dev/null; then
        huggingface-cli download "$repo" --local-dir "$dest_dir/$repo" --local-dir-use-symlinks False
    else
        echo -e "${RED}Error: huggingface-cli not found${NC}"
        echo "Install with: pip install huggingface-hub"
        exit 1
    fi

    echo -e "${GREEN}✓ Downloaded to: $dest_dir/$repo${NC}"
}

download_from_civitai() {
    local url=$1
    local dest_dir=$2

    # If it's just a number, construct the API URL
    if [[ "$url" =~ ^[0-9]+$ ]]; then
        url="https://civitai.com/api/download/models/$url"
    fi

    echo -e "${YELLOW}Downloading from Civitai...${NC}"
    echo -e "URL: $url"

    # Get filename from Content-Disposition header or URL
    local filename=$(curl -sI "$url" | grep -i 'content-disposition' | sed -n 's/.*filename="\?\([^"]*\)"\?.*/\1/p' | tr -d '\r')

    if [ -z "$filename" ]; then
        filename="model_$(date +%s).safetensors"
    fi

    echo -e "Saving as: ${BLUE}$filename${NC}"

    # Download with progress bar
    curl -L -o "$dest_dir/$filename" "$url" --progress-bar

    echo -e "${GREEN}✓ Downloaded to: $dest_dir/$filename${NC}"
}

# Parse arguments
if [ $# -lt 2 ]; then
    show_usage
    exit 1
fi

SOURCE=$1
URL=$2
DEST_TYPE=${3:-sd}

# Determine destination directory
case $DEST_TYPE in
    sd)
        DEST_DIR="$MODELS_DIR"
        ;;
    lora)
        DEST_DIR="$LORA_DIR"
        ;;
    vae)
        DEST_DIR="$VAE_DIR"
        ;;
    *)
        echo -e "${RED}Unknown destination: $DEST_TYPE${NC}"
        show_usage
        exit 1
        ;;
esac

# Create destination directory if it doesn't exist
mkdir -p "$DEST_DIR"

# Download based on source
case $SOURCE in
    hf|huggingface)
        download_from_huggingface "$URL" "$DEST_DIR"
        ;;
    civitai)
        download_from_civitai "$URL" "$DEST_DIR"
        ;;
    *)
        echo -e "${RED}Unknown source: $SOURCE${NC}"
        show_usage
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}Download complete!${NC}"
echo -e "Restart Forge Neo to see the new model in the UI"
