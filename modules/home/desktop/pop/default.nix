{ pkgs, lib, ... }:
let
  pop = pkgs.stdenv.mkDerivation rec {
    pname = "pop";
    version = "8.0.21";

    src = ./pop_8.0.21_amd64.deb;

    nativeBuildInputs = with pkgs; [
      autoPatchelfHook
      dpkg
      makeWrapper
    ];

    buildInputs = with pkgs; [
      alsa-lib
      at-spi2-atk
      at-spi2-core
      cairo
      cups
      dbus
      expat
      gdk-pixbuf
      glib
      gtk3
      libdrm
      libnotify
      libxkbcommon
      mesa
      nspr
      nss
      pango
      systemd
      xorg.libX11
      xorg.libXcomposite
      xorg.libXdamage
      xorg.libXext
      xorg.libXfixes
      xorg.libXrandr
      xorg.libxcb
      xorg.libxshmfence
    ];

    runtimeDependencies = with pkgs; [
      libGL
      libva
      pipewire
      wayland
    ];

    unpackPhase = ''
      runHook preUnpack
      # Extract .deb manually to avoid setuid permission errors with chrome-sandbox
      ar x $src
      tar xf data.tar.xz --no-same-permissions
      runHook postUnpack
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p $out/bin $out/lib/pop $out/share

      cp -r usr/lib/pop/* $out/lib/pop/
      cp -r usr/share/* $out/share/

      # Create wrapper script
      makeWrapper $out/lib/pop/Pop $out/bin/pop \
        --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath runtimeDependencies}" \
        --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations}}"

      # Fix desktop file
      substituteInPlace $out/share/applications/pop.desktop \
        --replace-fail "/usr/bin/pop" "$out/bin/pop" \
        --replace-fail "/usr/share/pixmaps/pop.png" "$out/share/pixmaps/pop.png"

      runHook postInstall
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
    exec = "env NIXOS_OZONE_WL=1 ${pop}/bin/pop %U";
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
