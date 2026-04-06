{ pkgs, lib, ... }:
let
  helixTooling = with pkgs; [
    awk-language-server
    bash-language-server
    basedpyright
    black
    clang-tools
    cmake-format
    delve
    docker-compose-language-service
    dockerfile-language-server
    elixir
    elixir-ls
    erlang-language-platform
    fourmolu
    gleam
    go
    golangci-lint-langserver
    gopls
    graphql-language-service-cli
    haskell-language-server
    jq-lsp
    lua-language-server
    markdown-oxide
    neocmakelsp
    nixfmt
    prettier
    sql-formatter
    typescript
    prisma-language-server
    protols
    ruby
    rubyPackages.ruby-lsp
    rubyPackages.syntax_tree
    rust-analyzer
    rustfmt
    shfmt
    socat
    sqls
    stylua
    taplo
    terraform
    terraform-ls
    texlab
    texlivePackages.latexindent
    typescript-language-server
    vscode-langservers-extracted
    vscode-js-debug
    yaml-language-server
    yamlfmt
    zls
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
        # Cross-platform packages
        _1password-cli
        man-pages
        cargo
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
        glow
        gnumake
        jq # JSON processor
        ncdu # disk space
        nil
        nix-prefetch-github
        nodejs_22
        openssl
        python312
        ripgrep
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
