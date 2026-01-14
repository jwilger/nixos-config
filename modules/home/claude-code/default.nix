{
  config,
  lib,
  pkgs,
  ...
}:
let
  # Marketplaces to add (GitHub repos)
  marketplaces = [
    "jwilger/claude-code-plugins"
  ];

  # Plugins to install (plugin@marketplace format)
  plugins = [
    "marvin-output-style@jwilger-claude-plugins"
    "sdlc@jwilger-claude-plugins"
    "bootstrap@jwilger-claude-plugins"
  ];

  # Generate marketplace add commands
  marketplaceCommands = lib.concatStringsSep "\n" (
    map (repo: ''
      if ! claude plugin marketplace list 2>/dev/null | grep -q "${lib.last (lib.splitString "/" repo)}"; then
        echo "Adding marketplace: ${repo}"
        claude plugin marketplace add "${repo}" || true
      fi
    '') marketplaces
  );

  # Generate plugin install commands
  pluginCommands = lib.concatStringsSep "\n" (
    map (plugin: ''
      if ! claude plugin marketplace list 2>/dev/null | grep -q "${plugin}"; then
        echo "Installing plugin: ${plugin}"
        claude plugin install "${plugin}" || true
      fi
    '') plugins
  );
in
{
  # Create symlink for ~/.claude directory
  home.file.".claude" = {
    source = config.lib.file.mkOutOfStoreSymlink "/etc/nixos/modules/home/claude-code/config";
  };

  # Create symlink for ~/.claude.json
  home.file.".claude.json" = {
    source = config.lib.file.mkOutOfStoreSymlink "/etc/nixos/modules/home/claude-code/claude.json";
  };

  # Install the claude-notify script
  home.file.".local/bin/claude-notify" = {
    source = ./claude-notify.sh;
    executable = true;
  };

  # Activation script to install Claude Code and set up plugins
  home.activation.claudeCodeSetup = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    # Install Claude Code if not present
    if ! command -v claude &> /dev/null; then
      echo "Installing Claude Code..."
      ${pkgs.curl}/bin/curl -fsSL https://claude.ai/install.sh | sh
      # Add to PATH for this session
      export PATH="$HOME/.local/bin:$PATH"
    fi

    # Only set up plugins if claude is available and user is logged in
    if command -v claude &> /dev/null; then
      # Check if logged in (credentials exist)
      if [ -f "$HOME/.claude/.credentials.json" ]; then
        echo "Setting up Claude Code marketplaces and plugins..."

        # Add marketplaces
        ${marketplaceCommands}

        # Install plugins
        ${pluginCommands}
      else
        echo "Claude Code not logged in - skipping plugin setup. Run 'claude' to log in."
      fi
    fi
  '';
}
