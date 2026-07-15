{
  lib,
  pkgs,
  ...
}:
let
  browserPackage = pkgs.chromium;
  browserExe = lib.getExe browserPackage;
  chromePersonal = pkgs.writeShellApplication {
    name = "chrome-personal";
    runtimeInputs = [ browserPackage ];
    text = ''
      exec ${browserExe} --profile-directory=Default "$@"
    '';
  };
  chromeWork = pkgs.writeShellApplication {
    name = "chrome-work";
    runtimeInputs = [ browserPackage ];
    text = ''
      exec ${browserExe} --profile-directory="Profile 4" "$@"
    '';
  };
  chromePick = pkgs.writeShellApplication {
    name = "chrome-pick";
    runtimeInputs = [
      chromePersonal
      chromeWork
      pkgs.fuzzel
    ];
    text = ''
      choice="$(printf 'Personal\nWork\n' | fuzzel --dmenu --prompt='Chromium profile: ' --lines=2 --width=24)" || exit 0

      case "$choice" in
        Personal)
          exec chrome-personal --new-window "$@"
          ;;
        Work)
          exec chrome-work --new-window "$@"
          ;;
        *)
          exit 0
          ;;
      esac
    '';
  };
  nignite = pkgs.writeShellApplication {
    name = "nignite";
    runtimeInputs = [
      chromePick
      pkgs.jq
      pkgs.niri
    ];
    text = ''
      focused_workspace_id="$(
        niri msg -j focused-window 2>/dev/null \
          | jq -er '.workspace_id // empty' 2>/dev/null \
          || niri msg -j workspaces 2>/dev/null \
          | jq -er '.[] | select(.is_focused == true) | .id' 2>/dev/null \
          || true
      )"

      # Chromium cannot target a particular existing window when opening a URL.
      # Only a bare invocation reuses the Chromium window on this workspace;
      # URLs always open a new profile-selected window on the focused workspace.
      if [ -n "$focused_workspace_id" ] && [ "$#" -eq 0 ]; then
        chrome_window_id="$(
          niri msg -j windows 2>/dev/null \
            | jq -er --argjson workspace_id "$focused_workspace_id" '
                [
                  .[]
                  | select(.workspace_id == $workspace_id)
                  | select(
                      ((.app_id // "") | test("chrome|chromium"; "i"))
                      or ((.title // "") | test("chrome|chromium"; "i"))
                    )
                ][0].id
              ' 2>/dev/null \
            || true
        )"

        if [ -n "$chrome_window_id" ]; then
          niri msg action focus-window --id "$chrome_window_id" >/dev/null 2>&1 || true
          exit 0
        fi
      fi

      exec chrome-pick "$@"
    '';
  };
in
{
  home.packages = [
    browserPackage
    chromePersonal
    chromePick
    chromeWork
    nignite
  ];

  xdg.desktopEntries = {
    chrome-personal = {
      name = "Chromium Personal";
      exec = "${lib.getExe chromePersonal} %U";
      icon = "chromium";
      categories = [
        "Network"
        "WebBrowser"
      ];
      genericName = "Web Browser";
      mimeType = [
        "text/html"
        "x-scheme-handler/http"
        "x-scheme-handler/https"
      ];
      noDisplay = false;
      terminal = false;
    };
    chrome-work = {
      name = "Chromium Work";
      exec = "${lib.getExe chromeWork} %U";
      icon = "chromium";
      categories = [
        "Network"
        "WebBrowser"
      ];
      genericName = "Web Browser";
      mimeType = [
        "text/html"
        "x-scheme-handler/http"
        "x-scheme-handler/https"
      ];
      noDisplay = false;
      terminal = false;
    };
    chromium = {
      name = "Chromium";
      noDisplay = true;
    };
    nignite = {
      name = "Chromium Workspace Router";
      exec = "${lib.getExe nignite} %U";
      icon = "chromium";
      categories = [
        "Network"
        "WebBrowser"
      ];
      mimeType = [
        "text/html"
        "x-scheme-handler/about"
        "x-scheme-handler/http"
        "x-scheme-handler/https"
        "x-scheme-handler/unknown"
      ];
      noDisplay = true;
      terminal = false;
    };
  };

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/html" = [ "nignite.desktop" ];
      "x-scheme-handler/about" = [ "nignite.desktop" ];
      "x-scheme-handler/http" = [ "nignite.desktop" ];
      "x-scheme-handler/https" = [ "nignite.desktop" ];
      "x-scheme-handler/unknown" = [ "nignite.desktop" ];
    };
  };
}
