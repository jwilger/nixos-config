#!/usr/bin/env bash
# Script to automatically update package hashes in overlays.nix
set -euo pipefail

echo "Building packages to extract correct hashes..."
echo "This will fail - that's expected. We'll extract the correct hashes from the errors."
echo ""

# Try to build codex and capture the hash
echo "==> Getting codex cargo hash..."
codex_output=$(nix-build --no-out-link -E '
with import <nixpkgs> {
  overlays = [
    (final: prev: {
      codex = prev.codex.overrideAttrs (oldAttrs: rec {
        version = "0.55.0";
        src = final.fetchFromGitHub {
          owner = "openai";
          repo = "codex";
          rev = "rust-v0.55.0";
          hash = "sha256-gtYLMqQ3szUJMN1Jdcy2BPrJN8bxvrt0nVShcC2/JAA=";
        };
        cargoHash = final.lib.fakeHash;
      });
    })
  ];
}; codex' 2>&1 || true)

codex_hash=$(echo "$codex_output" | grep -oP 'got:\s+\Ksha256-[A-Za-z0-9+/=]+' | head -1 || echo "")

if [ -n "$codex_hash" ]; then
  echo "Found codex cargoHash: $codex_hash"
  sed -i "s|cargoHash = final.lib.fakeHash;|cargoHash = \"$codex_hash\";|" overlays.nix
  echo "✓ Updated codex hash in overlays.nix"
else
  echo "⚠ Could not extract codex hash - check build output manually"
fi

echo ""
echo "==> Getting claude-code npm hash..."
claude_output=$(nix-build --no-out-link -E '
with import <nixpkgs> {
  overlays = [
    (final: prev: {
      claude-code = prev.claude-code.overrideAttrs (oldAttrs: rec {
        version = "2.0.34-unstable";
        src = final.fetchFromGitHub {
          owner = "anthropics";
          repo = "claude-code";
          rev = "b95fa46499043c07bc32bc36b575433e419d9e37";
          hash = "sha256-iSpTTEQL24CE9nBjfjuGbAnUADJLLyzzr0F7JSw3xhY=";
        };
        npmDepsHash = final.lib.fakeHash;
      });
    })
  ];
}; claude-code' 2>&1 || true)

claude_hash=$(echo "$claude_output" | grep -oP 'got:\s+\Ksha256-[A-Za-z0-9+/=]+' | head -1 || echo "")

if [ -n "$claude_hash" ]; then
  echo "Found claude-code npmDepsHash: $claude_hash"
  sed -i "s|npmDepsHash = final.lib.fakeHash;|npmDepsHash = \"$claude_hash\";|" overlays.nix
  echo "✓ Updated claude-code hash in overlays.nix"
else
  echo "⚠ Could not extract claude-code hash - check build output manually"
fi

echo ""
echo "==> Hash update complete!"
echo "Run 'git diff overlays.nix' to see the changes"
