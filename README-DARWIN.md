# macOS (nix-darwin) Configuration

This directory contains a nix-darwin configuration for macOS that shares as much as possible with the NixOS configurations while respecting platform differences.

## What's Included

### Shared Components

These components work identically on both macOS and Linux:

- **Shell Environment**: zsh with starship prompt, zellij terminal multiplexer
- **Development Tools**: neovim (LazyVim), git, cargo, nodejs, python3
- **CLI Tools**: bat, eza, fd, fzf, ripgrep, yazi, lazygit
- **Theme**: Catppuccin Mocha with Lavender accent
- **Wallpaper**: Same wallpaper as Linux desktop (auto-applied)

### macOS-Specific Features

- **System Preferences**: Declaratively managed Dock, Finder, trackpad, keyboard settings
- **Homebrew Integration**: Declarative package management for GUI apps
- **Touch ID**: Enabled for sudo authentication
- **Window Management**: AeroSpace tiling window manager
- **Applications via Homebrew**:
  - Development: iTerm2, Docker, 1Password
  - Communication: Slack, Zoom
  - Utilities: Caffeine, Tuple
  - Media: Firefox, Spotify, VLC

## Prerequisites

- macOS (tested on latest version)
- Admin access to your Mac
- Internet connection

## Installation

### Automated Installation

1. Clone this repository to your Mac:

   ```bash
   git clone <repository-url> ~/nixos-config
   cd ~/nixos-config
   ```

2. Run the installation script:

   ```bash
   ./scripts/install-darwin.sh
   ```

   This script will:
   - Install Nix if not present
   - Build the nix-darwin configuration
   - Activate the system configuration
   - Set up Homebrew integration

3. Restart your terminal

4. Install Homebrew apps:

   ```bash
   brew bundle --global
   ```

### Manual Installation

If you prefer to install manually:

1. Install Nix:

   ```bash
   curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
   ```

2. Build the configuration:

   ```bash
   nix build .#darwinConfigurations.darwin.system --extra-experimental-features 'nix-command flakes'
   ```

3. Activate:

   ```bash
   ./result/sw/bin/darwin-rebuild switch --flake .#darwin
   ```

## Post-Installation

### iTerm2 Configuration

1. Open iTerm2
2. Go to Preferences → Profiles → Colors
3. Import the Catppuccin Mocha color scheme if desired
4. Set JetBrainsMono Nerd Font as the default font

### 1Password

1. Open 1Password
2. Sign in to your account
3. Enable CLI integration in Settings → Developer

### AeroSpace Window Manager

AeroSpace is installed via Homebrew. Configuration file:

```bash
~/.config/aerospace/aerospace.toml
```

You may want to customize keybindings to your preference.

### Wallpaper

The wallpaper should be automatically applied. If not:

```bash
osascript -e 'tell application "System Events" to tell every desktop to set picture to "~/Pictures/wallpaper.png"'
```

## Updating the Configuration

### Update System Configuration

After making changes to configuration files:

```bash
darwin-rebuild switch --flake ~/nixos-config#darwin
```

### Update Flake Inputs

To update nixpkgs and other inputs to their latest versions:

```bash
nix flake update --flake ~/nixos-config
darwin-rebuild switch --flake ~/nixos-config#darwin
```

### Update Homebrew Packages

```bash
brew update
brew upgrade
```

Or let nix-darwin handle it (automatic on configuration rebuild).

## Directory Structure

```
.
├── flake.nix                          # Main flake with darwin configuration
├── hosts/
│   └── darwin/
│       └── default.nix                # macOS host configuration
├── modules/
│   ├── darwin/                        # macOS-specific system modules
│   │   ├── default.nix
│   │   ├── system.nix                 # System preferences
│   │   └── homebrew.nix               # Homebrew packages
│   └── home/                          # Shared home-manager modules
│       ├── darwin/                    # macOS-specific home modules
│       │   ├── default.nix
│       │   ├── iterm2.nix
│       │   ├── wallpaper.nix
│       │   └── packages.nix
│       ├── git.nix                    # Works on both platforms
│       ├── nvim/                      # Works on both platforms
│       ├── zsh.nix                    # Works on both platforms
│       └── ...
└── scripts/
    └── install-darwin.sh              # Installation script
```

## Common Tasks

### Add a New Homebrew Application

Edit `modules/darwin/homebrew.nix`:

```nix
casks = [
  # ... existing casks
  "new-application"
];
```

Then rebuild:

```bash
darwin-rebuild switch --flake ~/nixos-config#darwin
```

### Change System Preferences

Edit `modules/darwin/system.nix` to modify Dock, Finder, or other macOS settings, then rebuild.

### Add a Nix Package

Edit `modules/home/packages.nix` for CLI tools or `modules/home/darwin/packages.nix` for macOS-specific packages.

## Troubleshooting

### "darwin-rebuild: command not found"

Source the Nix profile:

```bash
. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
```

Or restart your terminal.

### Homebrew Apps Not Installing

Ensure Homebrew is installed and run:

```bash
brew bundle --global
```

### Build Failures

Check that all inputs are available:

```bash
nix flake check --flake ~/nixos-config
```

### System Preferences Not Applying

Some preferences require a logout/login or full restart to take effect.

### Reverting Changes

nix-darwin creates generations. List them:

```bash
darwin-rebuild --list-generations
```

Rollback to a previous generation:

```bash
darwin-rebuild switch --rollback
```

## Differences from NixOS Configuration

### What Doesn't Work on macOS

- COSMIC desktop environment (Linux-only)
- Systemd services
- Linux-specific hardware configurations
- Wayland-specific tools (wl-clipboard, wlogout)
- Linux-specific system packages (gparted, libnotify, etc.)

### What's Different

- GUI applications installed via Homebrew instead of Nix (better integration on macOS)
- System preferences managed via nix-darwin instead of NixOS modules
- User directory is `/Users/${username}` instead of `/home/${username}`
- Architecture is `aarch64-darwin` (Apple Silicon) or `x86_64-darwin` (Intel)

## Contributing

When adding new packages or features:

1. **For cross-platform tools**: Add to `modules/home/packages.nix` with `lib.optionals pkgs.stdenv.isLinux` for Linux-only packages
2. **For macOS system settings**: Add to `modules/darwin/system.nix`
3. **For macOS GUI apps**: Add to `modules/darwin/homebrew.nix`
4. **For macOS home settings**: Add to `modules/home/darwin/`

Test both platforms when possible.

## Resources

- [nix-darwin Documentation](https://github.com/LnL7/nix-darwin)
- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [Nix Flakes](https://nixos.wiki/wiki/Flakes)
- [Catppuccin Theme](https://github.com/catppuccin/nix)
