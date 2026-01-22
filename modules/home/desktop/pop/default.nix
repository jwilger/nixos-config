{ pkgs, lib, ... }:
let
  # First extract the .deb contents
  pop-unwrapped = pkgs.stdenv.mkDerivation rec {
    pname = "pop-unwrapped";
    version = "8.0.21";

    src = ./pop_8.0.21_amd64.deb;

    nativeBuildInputs = with pkgs; [ dpkg ];

    unpackPhase = ''
      runHook preUnpack
      ar x $src
      tar xf data.tar.xz --no-same-permissions
      runHook postUnpack
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp -r usr/* $out/
      runHook postInstall
    '';

    meta = with lib; {
      description = "Screen sharing for remote teams (unwrapped)";
      homepage = "https://pop.com";
      license = licenses.unfree;
      platforms = [ "x86_64-linux" ];
    };
  };

  # Wrap with FHS environment for compatibility
  pop = pkgs.buildFHSEnv {
    name = "pop";
    targetPkgs =
      pkgs: with pkgs; [
        # Core
        glib
        glibc
        nss
        nspr
        dbus
        atk
        at-spi2-atk
        at-spi2-core
        cups
        gtk3
        gdk-pixbuf
        libdrm
        libnotify
        libsecret
        libuuid
        libxkbcommon
        mesa
        pango
        systemd
        xdg-utils

        # X11
        xorg.libX11
        xorg.libXcomposite
        xorg.libXcursor
        xorg.libXdamage
        xorg.libXext
        xorg.libXfixes
        xorg.libXi
        xorg.libXrandr
        xorg.libXrender
        xorg.libXScrnSaver
        xorg.libXtst
        xorg.libxcb
        xorg.libxshmfence

        # Graphics
        libGL
        libgbm
        libva
        libvdpau
        vulkan-loader

        # Audio/Video
        alsa-lib
        libpulseaudio
        pipewire

        # Wayland
        wayland

        # Misc
        cairo
        expat
        ffmpeg
        freetype
        harfbuzz
        icu
        libpng
        libwebp
        zlib
      ];

    runScript = "${pop-unwrapped}/lib/pop/Pop";

    extraInstallCommands = ''
      mkdir -p $out/share
      cp -r ${pop-unwrapped}/share/* $out/share/

      # Fix desktop file
      substituteInPlace $out/share/applications/pop.desktop \
        --replace-fail "/usr/bin/pop" "$out/bin/pop" \
        --replace-fail "/usr/share/pixmaps/pop.png" "$out/share/pixmaps/pop.png"
    '';

    meta = with lib; {
      description = "Screen sharing for remote teams with multiplayer drawing and control";
      homepage = "https://pop.com";
      license = licenses.unfree;
      platforms = [ "x86_64-linux" ];
      mainProgram = "pop";
    };
  };
in
{
  home.packages = [ pop ];

  xdg.desktopEntries.pop = {
    name = "Pop";
    comment = "Screen sharing for remote teams";
    # Pop currently only supports X11, runs via XWayland
    exec = "${pop}/bin/pop %U";
    icon = "${pop}/share/pixmaps/pop.png";
    terminal = false;
    type = "Application";
    categories = [
      "Network"
      "InstantMessaging"
    ];
    mimeType = [ "x-scheme-handler/pop" ];
    settings = {
      StartupNotify = "true";
      StartupWMClass = "Pop";
    };
  };

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "x-scheme-handler/pop" = "pop.desktop";
    };
  };
}
