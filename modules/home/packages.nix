{ pkgs, lib, ... }:
let
  helixTooling =
    with pkgs;
    [
      awk-language-server
      bash-language-server
      basedpyright
      black
      bubblewrap
      clang-tools
      lldb
      cmake-format
      codeql
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
      marksman
      markdown-oxide
      neocmakelsp
      nixfmt-rfc-style
      nodePackages.prettier
      nodePackages.sql-formatter
      nodePackages.typescript
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
in
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
      bc # calculator for audio processing
      cliphist # clipboard manager (Wayland)
      dwt1-shell-color-scripts
      gcc
      gparted # partition manager
      gtrash # rm replacement, put deleted files in system trash
      libnotify
      nitch # systhem fetch util
      pamixer # command-line audio mixer
      pipx # Python package installer for Piper TTS
      poweralertd
      pulseaudio # provides paplay for audio playback
      sox # audio effects processing
      wl-clipboard # clipboard utils for wayland (wl-copy, wl-paste)
      wlogout
      xdg-utils
    ]
  )
  ++ helixTooling;
}
