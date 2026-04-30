{ pkgs, lib, ... }:
let
  # Conservative ad-hoc-editor toolset only. Project-specific toolchains
  # and LSPs (rust-analyzer, gopls, elixir-ls, haskell-language-server,
  # terraform-ls, texlab, typescript-language-server, zls, etc.) and the
  # corresponding compilers/runtimes (go, ruby, elixir, terraform, cargo,
  # python, nodejs) come from each project's flake.nix via direnv.
  helixTooling = with pkgs; [
    awk-language-server
    bash-language-server
    basedpyright
    black
    clang-tools
    cmake-format
    docker-compose-language-service
    dockerfile-language-server
    graphql-language-service-cli
    jq-lsp
    lua-language-server
    markdown-oxide
    neocmakelsp
    nixfmt
    prettier
    shfmt
    socat
    sql-formatter
    sqls
    stylua
    taplo
    vscode-langservers-extracted
    yaml-language-server
    yamlfmt
  ];
  helixToolingLinux = with pkgs; [
    # macOS uses Homebrew for these tools
    lldb
    marksman
  ];
in
{
  home.packages =
    (
      with pkgs;
      [
        # Cross-platform packages.
        # Toolchains (cargo, nodejs_22, python312) intentionally dropped:
        # they live in per-project flake.nix files and are activated by
        # direnv. For one-off scripts use `nix run nixpkgs#<pkg> -- ...`.
        _1password-cli
        man-pages
        cbonsai # terminal screensaver
        cmatrix
        delta
        entr # perform action when file change
        eza # ls replacement
        fd # find replacement
        ffmpeg
        file # Show file information
        fzf # fuzzy finder
        gh
        git-crypt
        glab
        glow
        gnumake
        jq # JSON processor
        ncdu # disk space
        nil
        nix-prefetch-github
        openssl
        ripgrep
        rtk # reduce token use by llm cli tools
        statix
        tdf # cli pdf viewer
        unzip
        uv
      ]
      # Linux-only packages
      ++ lib.optionals pkgs.stdenv.isLinux [
        telegram-desktop
        bc # calculator for audio processing
        bubblewrap
        codeql
        cliphist # clipboard manager (Wayland)
        dwt1-shell-color-scripts
        gcc
        gparted # partition manager
        gtrash # rm replacement, put deleted files in system trash
        libnotify
        nitch # systhem fetch util
        pamixer # command-line audio mixer
        pipx # Python package installer for Piper TTS
        pre-commit
        poweralertd
        pulseaudio # provides paplay for audio playback
        sox # audio effects processing
        wl-clipboard # clipboard utils for wayland (wl-copy, wl-paste)
        wlogout
        xdg-utils
      ]
    )
    ++ helixTooling
    ++ lib.optionals pkgs.stdenv.isLinux helixToolingLinux;
}
