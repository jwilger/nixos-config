#!/usr/bin/env bash
set -euo pipefail

echo "=== IronClaw Setup ==="
echo ""
echo "This script will:"
echo "  1. Create a 1Password item with your secrets"
echo "  2. Store the 1Password Service Account token"
echo "  3. Update your NixOS config with your Telegram user ID"
echo ""

# --- Step 1: Gather values ---

read -rp "Anthropic API key: " ANTHROPIC_KEY
if [[ -z "$ANTHROPIC_KEY" ]]; then
  echo "Error: Anthropic API key is required."
  exit 1
fi

read -rp "Telegram bot token (from @BotFather or ~/.openclaw/.env): " TELEGRAM_TOKEN
if [[ -z "$TELEGRAM_TOKEN" ]]; then
  echo "Error: Telegram bot token is required."
  exit 1
fi

read -rp "Your Telegram user ID (message @userinfobot on Telegram): " TELEGRAM_USER_ID
if [[ -z "$TELEGRAM_USER_ID" ]]; then
  echo "Error: Telegram user ID is required."
  exit 1
fi

# Validate that the Telegram user ID is numeric
if ! [[ "$TELEGRAM_USER_ID" =~ ^[0-9]+$ ]]; then
  echo "Error: Telegram user ID must be a number."
  exit 1
fi

read -rp "1Password vault name [Private]: " OP_VAULT
OP_VAULT="${OP_VAULT:-Private}"

# --- Step 2: Create 1Password item ---

echo ""
echo "Creating 1Password item 'IronClaw' in vault '${OP_VAULT}'..."

op item create --category=login --title="IronClaw" --vault="$OP_VAULT" \
  "anthropic-api-key[password]=$ANTHROPIC_KEY" \
  "telegram-bot-token[password]=$TELEGRAM_TOKEN" \
  --no-color >/dev/null

echo "  Done."

# --- Step 3: Service Account token ---

echo ""
echo "Now you need a 1Password Service Account token."
echo "If you don't have one yet, create it at:"
echo "  https://my.1password.com -> Developer Tools -> Infrastructure Secrets -> Service Accounts"
echo "Grant it read access to the '${OP_VAULT}' vault."
echo ""
read -rp "1Password Service Account token: " SA_TOKEN
if [[ -z "$SA_TOKEN" ]]; then
  echo "Error: Service Account token is required."
  exit 1
fi

echo ""
echo "Storing Service Account token at /etc/ironclaw/op-token..."
sudo mkdir -p /etc/ironclaw
echo -n "$SA_TOKEN" | sudo tee /etc/ironclaw/op-token >/dev/null
sudo chmod 600 /etc/ironclaw/op-token
echo "  Done."

# --- Step 4: Update NixOS config ---

GREGOR_CONFIG="/etc/nixos/hosts/gregor/default.nix"

echo ""
echo "Updating ${GREGOR_CONFIG} with your Telegram user ID..."

sed -i "s/ownerId = 0;/ownerId = ${TELEGRAM_USER_ID};/" "$GREGOR_CONFIG"
sed -i "s/allowedUserIds = \[ \];/allowedUserIds = [ \"${TELEGRAM_USER_ID}\" ];/" "$GREGOR_CONFIG"

# Update vault references if not using "Private"
if [[ "$OP_VAULT" != "Private" ]]; then
  sed -i "s|op://Private/|op://${OP_VAULT}/|g" "$GREGOR_CONFIG"
fi

echo "  Done."

# --- Step 5: Verify ---

echo ""
echo "Verifying 1Password access..."
export OP_SERVICE_ACCOUNT_TOKEN="$SA_TOKEN"
if op read "op://${OP_VAULT}/IronClaw/anthropic-api-key" --no-newline >/dev/null 2>&1; then
  echo "  1Password secret access verified."
else
  echo "  WARNING: Could not read secrets. Check that the Service Account has access to the '${OP_VAULT}' vault."
fi

echo ""
echo "=== Setup complete ==="
echo ""
echo "Next steps:"
echo "  1. Review the changes:  git diff hosts/gregor/default.nix"
echo "  2. Rebuild:             sudo nixos-rebuild switch --flake /etc/nixos"
echo "  3. Check service:       systemctl status ironclaw"
echo "  4. View logs:           journalctl -u ironclaw -f"
