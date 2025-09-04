{ pkgs, config, lib, ... }:
{
  # Ensure nodejs is available
  home.packages = with pkgs; [
    nodejs
  ];

  # Create an activation script that installs/updates Claude Code from npm
  home.activation.installClaudeCode = lib.hm.dag.entryAfter ["writeBoundary"] ''
    # Ensure .local/bin directory exists
    mkdir -p $HOME/.local/bin
    
    # Function to check Claude Code version
    check_claude_version() {
      if [ -x "$HOME/.local/bin/claude" ]; then
        # Try to get version from the installed claude command
        current_version=$(${pkgs.nodejs}/bin/node "$HOME/.local/bin/claude" --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "unknown")
      else
        current_version="not installed"
      fi
      
      # Get latest version from npm
      latest_version=$(${pkgs.nodejs}/bin/npm view @anthropic-ai/claude-code version 2>/dev/null || echo "unknown")
      
      echo "Current Claude Code version: $current_version"
      echo "Latest Claude Code version: $latest_version"
      
      # If versions differ or claude doesn't exist, we need to install
      if [ "$current_version" != "$latest_version" ] || [ ! -x "$HOME/.local/bin/claude" ]; then
        return 0  # Need to install
      else
        return 1  # Already up to date
      fi
    }
    
    # Check if we need to update
    if check_claude_version; then
      echo "Installing/updating Claude Code from npm..."
      
      # Create a temporary directory for npm installation
      temp_dir=$(mktemp -d)
      cd "$temp_dir"
      
      # Install Claude Code package
      echo "Downloading @anthropic-ai/claude-code package..."
      ${pkgs.nodejs}/bin/npm install @anthropic-ai/claude-code || {
        echo "Failed to download Claude Code from npm"
        rm -rf "$temp_dir"
        exit 1
      }
      
      # Use npx to run the install command from the package
      # The install command expects the installation directory as input
      echo "Running Claude Code installation..."
      echo "$HOME/.local/bin" | PATH="${pkgs.nodejs}/bin:$PATH" ${pkgs.nodejs}/bin/npx @anthropic-ai/claude-code install || {
        echo "Failed to install Claude Code"
        rm -rf "$temp_dir"
        exit 1
      }
      
      # Verify installation was successful
      if [ -x "$HOME/.local/bin/claude" ]; then
        echo "✓ Claude Code installed successfully at $HOME/.local/bin/claude"
        installed_version=$(${pkgs.nodejs}/bin/node "$HOME/.local/bin/claude" --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "unknown")
        echo "✓ Installed version: $installed_version"
      else
        echo "Error: Claude Code installation completed but binary not found at $HOME/.local/bin/claude"
        rm -rf "$temp_dir"
        exit 1
      fi
      
      # Clean up temp directory
      rm -rf "$temp_dir"
    else
      echo "✓ Claude Code is already up to date"
    fi
  '';
  
  # Add .local/bin to PATH if not already there
  home.sessionPath = [ "$HOME/.local/bin" ];
}