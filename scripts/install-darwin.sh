#!/usr/bin/env bash

# Installation script for nix-darwin configuration
# This script sets up Nix and nix-darwin on a fresh macOS system

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== nix-darwin Installation Script ===${NC}"
echo ""

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo -e "${RED}Error: This script is only for macOS${NC}"
    exit 1
fi

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Step 1: Install Nix if not present
echo -e "${YELLOW}Step 1: Checking Nix installation...${NC}"
if ! command_exists nix; then
    echo "Nix not found. Installing Nix..."
    echo "This will require sudo permissions."

    # Install Nix using the Determinate Systems installer (recommended for macOS)
    # This installer handles modern macOS security requirements better
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

    # Source Nix
    if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
        . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
    fi

    echo -e "${GREEN}Nix installed successfully!${NC}"
else
    echo -e "${GREEN}Nix is already installed.${NC}"
fi

# Verify Nix is available
if ! command_exists nix; then
    echo -e "${RED}Error: Nix installation failed or is not in PATH${NC}"
    echo "Please restart your terminal and run this script again."
    exit 1
fi

echo ""

# Step 2: Determine flake location
echo -e "${YELLOW}Step 2: Determining flake location...${NC}"

# Check if we're running from the repo
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FLAKE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

if [ -f "$FLAKE_DIR/flake.nix" ]; then
    echo -e "${GREEN}Found flake at: $FLAKE_DIR${NC}"
else
    echo -e "${RED}Error: Could not find flake.nix${NC}"
    echo "Please run this script from within your nix configuration repository."
    exit 1
fi

echo ""

# Step 3: Backup existing nix-darwin configuration if it exists
echo -e "${YELLOW}Step 3: Checking for existing nix-darwin configuration...${NC}"
if [ -e "/etc/nix/nix-darwin" ]; then
    echo "Existing nix-darwin configuration found. Creating backup..."
    sudo mv /etc/nix/nix-darwin /etc/nix/nix-darwin.backup-$(date +%Y%m%d-%H%M%S)
    echo -e "${GREEN}Backup created.${NC}"
fi

echo ""

# Step 4: Build and activate nix-darwin configuration
echo -e "${YELLOW}Step 4: Building and activating nix-darwin configuration...${NC}"
echo "This may take a while on first run..."

# First, we need to build the configuration
nix build "$FLAKE_DIR#darwinConfigurations.darwin.system" --extra-experimental-features 'nix-command flakes'

# Activate the configuration
./result/sw/bin/darwin-rebuild switch --flake "$FLAKE_DIR#darwin"

echo ""
echo -e "${GREEN}=== Installation Complete! ===${NC}"
echo ""
echo "Next steps:"
echo "1. Restart your terminal to load the new environment"
echo "2. Future updates can be applied with:"
echo "   darwin-rebuild switch --flake $FLAKE_DIR#darwin"
echo ""
echo "3. To update flake inputs (nixpkgs, etc.):"
echo "   nix flake update --flake $FLAKE_DIR"
echo ""
echo "4. Homebrew packages will be installed on next login or run:"
echo "   brew bundle --global"
echo ""
echo -e "${YELLOW}Note: Some applications (iTerm2, etc.) need to be configured manually.${NC}"
echo "Refer to README-DARWIN.md for detailed post-installation instructions."
