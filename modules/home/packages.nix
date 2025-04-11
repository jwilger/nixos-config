{ inputs, pkgs, ... }: 
let 
  _2048 = pkgs.callPackage ../../pkgs/2048/default.nix {}; 
in
{
  home.packages = (with pkgs; [
	  man-pages
    _1password-cli
    _1password-gui
    _2048
    audacity
    bitwise                           # cli tool for bit / hex manipulation
    bleachbit                         # cache cleaner
    cargo
    cbonsai                           # terminal screensaver
    cliphist                          # clipboard manager
    cmatrix
    dwt1-shell-color-scripts
    entr                              # perform action when file change
    evince                            # gnome pdf viewer
    eza                               # ls replacement
    fd                                # find replacement
    ffmpeg
    file                              # Show file information 
    fzf                               # fuzzy finder
    gcc
    gh
    gifsicle                          # gif utility
    gimp
    git-crypt
    gnumake
    goose-cli
    gparted                           # partition manager
    gtrash                            # rm replacement, put deleted files in system trash
    gtt                               # google translate TUI
    hexdump
    imv                               # image viewer
    inputs.alejandra.defaultPackage.${system}
    jdk17                             # java
    killall
    lazygit
    libnotify
    libreoffice
    mpv                               # video player
    nautilus     # file manager
    ncdu                              # disk space
    nil
    nitch                             # systhem fetch util
    nix-prefetch-github
    nodejs
    openssl
    pamixer                           # pulseaudio command line mixer
    pavucontrol                       # pulseaudio volume controle (GUI)
    pipes                             # terminal screensaver
    playerctl                         # controller for media players
    poweralertd
    powerline
    prismlauncher                     # minecraft launcher
    python3
    qalculate-gtk                     # calculator
    ripgrep
    soundwireserver                   # pass audio to android phone
    tdf                               # cli pdf viewer
    todo                              # cli todo list
    toipe                             # typing test in the terminal
    unzip
    uv
    valgrind                          # c memory analyzer
    wget
    wineWowPackages.wayland
    winetricks
    wl-clipboard                      # clipboard utils for wayland (wl-copy, wl-paste)
    wlogout
    xdg-utils
    xxd
    yazi                              # terminal file manager
    yt-dlp-light
    zellij
    zenity
  ]);
}
