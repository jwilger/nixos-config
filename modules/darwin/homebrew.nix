{
  config,
  pkgs,
  ...
}:
{
  # Homebrew declarative configuration
  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = true;
      upgrade = true;
      cleanup = "zap";
    };

    global = {
      brewfile = true;
    };

    # Taps (third-party repositories)
    taps = [
      "nikitabobko/tap" # For AeroSpace window manager
    ];

    # Formulae (CLI tools)
    brews = [
      # Development tools that work better via Homebrew on macOS
      "dotnet"
      "llvm"
      "marksman"
      "pre-commit"
    ];

    # Casks (GUI applications)
    casks = [
      # Window Management
      # "aerospace" # Tiling window manager (alternative to Rectangle)

      # Fonts
      "font-jetbrains-mono-nerd-font"

      # Utilities
      "iterm2" # Terminal emulator
      "wezterm" # Terminal emulator; Launchpad-visible alongside the nix-installed CLI
      "tuple" # Pair programming tool

      # Browsers
      "chromium"

      # Communication
      "slack"
      "zoom"

      # Media
      "spotify"
      "vlc"

      # Development
      "docker-desktop"

      # Password Management
      "1password"
      "1password-cli"
    ];

    # Mac App Store apps (requires mas-cli)
    masApps = {
      # Add Mac App Store apps here if needed
      # Example: "Xcode" = 497799835;
    };
  };

  system.activationScripts.postActivation.text = ''
    primary_user=${config.system.primaryUser}
    /bin/launchctl asuser "$(/usr/bin/id -u -- "$primary_user")" \
      /usr/bin/sudo --user="$primary_user" --set-home \
      ${pkgs.defaultbrowser}/bin/defaultbrowser chromium
  '';
}
