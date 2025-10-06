{ pkgs, config, ... }:
{
  # Install Zoom
  home.packages = with pkgs; [
    zoom-us
  ];

  # Configure Zoom to DISABLE embedded browser for SSO/OAuth authentication
  # SSO and Google login require the REAL browser (like Firefox) to handle
  # authentication properly. The embedded browser fails with referrer policy
  # errors and can't complete OAuth flows correctly.
  #
  # Setting these to FALSE forces Zoom to use xdg-open to launch your actual
  # browser, which then uses the zoom:// protocol handler to redirect back.
  #
  # Note on screen sharing:
  # Screen sharing on Wayland/Hyprland requires:
  # - pipewire and wireplumber (configured at system level)
  # - xdg-desktop-portal-hyprland (configured at system level)
  # - Proper portal configuration (see modules/desktop/default.nix)
  #
  # If screen sharing still doesn't work after rebuild:
  # 1. Check Zoom settings -> Share Screen -> Advanced -> Screen Capture Mode
  #    and ensure it's set to use PipeWire
  # 2. Try restarting Zoom completely
  # 3. As a last resort, consider using the Flatpak version of Zoom:
  #    flatpak install flathub us.zoom.Zoom
  xdg.configFile."zoomus.conf".text = ''
    embeddedBrowserForFacebookLogin=false
    embeddedBrowserForGoogleLogin=false
    embeddedBrowserForSSOLogin=false
  '';

  # Fix the desktop file to use the correct Zoom path instead of /usr/bin/zoom
  # This enables the zoom:// protocol handler to work for OAuth callbacks
  # Note: Must match the original "Zoom.desktop" filename (capital Z) to override it
  xdg.dataFile."applications/Zoom.desktop".text = ''
    [Desktop Entry]
    Name=Zoom Workplace
    Comment=Zoom Video Conference
    Exec=${config.home.profileDirectory}/bin/zoom %U
    Icon=Zoom
    Terminal=false
    Type=Application
    Encoding=UTF-8
    Categories=Network;Application;
    StartupWMClass=zoom
    MimeType=x-scheme-handler/zoommtg;x-scheme-handler/zoomus;x-scheme-handler/tel;x-scheme-handler/callto;x-scheme-handler/zoomphonecall;x-scheme-handler/zoomphonesms;x-scheme-handler/zoomcontactcentercall;application/x-zoom
    X-KDE-Protocols=zoommtg;zoomus;tel;callto;zoomphonecall;zoomphonesms;zoomcontactcentercall;
  '';

  # Register Zoom as the handler for zoom protocol URLs
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "x-scheme-handler/zoommtg" = "Zoom.desktop";
      "x-scheme-handler/zoomus" = "Zoom.desktop";
    };
  };
}