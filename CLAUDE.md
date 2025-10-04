# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Common Commands

### System Management

**Note**: Claude cannot execute `sudo` commands. After making configuration changes, the user must manually run the rebuild commands below.

- `sudo nixos-rebuild switch --flake .` - Apply configuration changes and switch to new generation (user must run)
- `sudo nixos-rebuild switch --flake .#gregor` - Apply configuration for specific host (gregor) (user must run)
- `sudo nixos-rebuild switch --flake .#vm` - Apply configuration for VM host (user must run)
- `nix flake check` - Validate flake configuration syntax and structure (Claude can run this)
- `nix flake update` - Update all flake inputs to latest versions
- `nix flake show` - Show available configurations and outputs

### Maintenance

- `sudo nix-collect-garbage -d` - Clean up old generations and free disk space
- `nix store optimise` - Deduplicate identical files in the Nix store

## Architecture Overview

This is a NixOS flake-based configuration supporting multiple hosts with a modular structure.

### Flake Structure

- **flake.nix**: Main flake definition with inputs (nixpkgs, home-manager, hyprland, catppuccin)
- **hosts/**: Host-specific configurations
  - `gregor/`: Primary desktop machine with full desktop environment
  - `vm/`: Virtual machine configuration
- **modules/**: Reusable configuration modules
  - `core/`: Essential system components (bootloader, network, security, etc.)
  - `desktop/`: Desktop environment setup (Hyprland, fonts, theming)
  - `home/`: Home Manager configurations for user-specific settings

### Key Design Patterns

- All hosts inherit from `modules/core` for base system functionality
- Desktop hosts additionally import `modules/desktop` for GUI components
- Home Manager configurations are host-specific via `home-manager.users.${username}.imports`
- Catppuccin theme system is used consistently across system and user configs
- Each module is focused on a single concern (git, nvim, zsh, etc.)

### Host Configuration

- **gregor**: Performance-optimized desktop with AMD graphics, Docker, BcacheFS scrubbing
- **vm**: Minimal configuration for virtual machine testing
- Both use username "jwilger" and x86_64-linux architecture

### Theme System

- Catppuccin "mocha" flavor with "lavender" accent color
- Applied at both system level (desktop module) and user level (home modules)
- Consistent across all applications (nvim, bat, starship, etc.)

### Development Environment

- Neovim with LazyVim configuration in `modules/home/nvim/`
- Shell setup with zsh, starship prompt, and zellij multiplexer
- Git configuration with user-specific settings
- Terminal applications: yazi (file manager), btop (system monitor), bat (cat replacement)
