{ pkgs, ... }: 
{
  home.packages = (with pkgs; [
    _1password-cli
	  man-pages
    cargo
    cbonsai                           # terminal screensaver
    cliphist                          # clipboard manager
    cmatrix
    dwt1-shell-color-scripts
    entr                              # perform action when file change
    eza                               # ls replacement
    fd                                # find replacement
    ffmpeg
    file                              # Show file information 
    fzf                               # fuzzy finder
    gcc
    gh
    git-crypt
    gnumake
    goose-cli
    gparted                           # partition manager
    gtrash                            # rm replacement, put deleted files in system trash
    lazygit
    libnotify
    ncdu                              # disk space
    nil
    nitch                             # systhem fetch util
    nix-prefetch-github
    nodejs
    openssl
    poweralertd
    powerline
    python3
    ripgrep
    tdf                               # cli pdf viewer
    unzip
    uv
    wl-clipboard                      # clipboard utils for wayland (wl-copy, wl-paste)
    wlogout
    xdg-utils
    zellij
  ]);
}
