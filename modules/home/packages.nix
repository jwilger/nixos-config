{ pkgs, lib, inputs, ... }:
{
  home.packages = (
    with pkgs;
    [
      # Cross-platform packages
      _1password-cli
      man-pages
      cargo
      cbonsai # terminal screensaver
      cmatrix
      codex # OpenAI's Rust-based coding agent (via overlay: 0.57.0)
      delta
      entr # perform action when file change
      eza # ls replacement
      fd # find replacement
      ffmpeg
      file # Show file information
      fzf # fuzzy finder
      gh
      git-crypt
      glow
      gnumake
      jq # JSON processor
      ncdu # disk space
      nil
      nix-prefetch-github
      nodejs
      openssl
      python3
      ripgrep
      statix
      tdf # cli pdf viewer
      unzip
      uv
    ]
    # Linux-only packages
    ++ lib.optionals pkgs.stdenv.isLinux [
      cliphist # clipboard manager (Wayland)
      dwt1-shell-color-scripts
      gcc
      gparted # partition manager
      gtrash # rm replacement, put deleted files in system trash
      libnotify
      nitch # systhem fetch util
      pamixer # command-line audio mixer
      poweralertd
      wl-clipboard # clipboard utils for wayland (wl-copy, wl-paste)
      wlogout
      xdg-utils
    ]
    # Beads issue tracker (from overlay, not flake input)
    ++ [ pkgs.beads ]
    # Claude Code CLI (from flake input - auto-updates hourly)
    ++ [ inputs.claude-code-nix.packages.${pkgs.system}.default ]
  );
}
