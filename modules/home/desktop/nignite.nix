{
  lib,
  pkgs,
  ...
}:
let
  browserPackage = pkgs.google-chrome;
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
      choice="$(printf 'Personal\nWork\n' | fuzzel --dmenu --prompt='Chrome profile: ' --lines=2 --width=24)" || exit 0

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
      pkgs.hyprland
      pkgs.jq
      pkgs.niri
    ];
    text = ''
      if [ -n "''${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
        focused_workspace_id="$(hyprctl -j activeworkspace | jq -er '.id' 2>/dev/null || true)"

        if [ -n "$focused_workspace_id" ] && [ "$#" -eq 0 ]; then
          chrome_window_address="$(
            hyprctl -j clients \
              | jq -er --argjson workspace_id "$focused_workspace_id" '
                  [
                    .[]
                    | select(.workspace.id == $workspace_id)
                    | select(
                        ((.class // "") | test("chrome|chromium"; "i"))
                        or ((.title // "") | test("chrome|chromium"; "i"))
                      )
                  ][0].address
                ' 2>/dev/null \
              || true
          )"

          if [ -n "$chrome_window_address" ]; then
            hyprctl dispatch focuswindow "address:$chrome_window_address" >/dev/null 2>&1 || true
            exit 0
          fi
        fi

        exec chrome-pick "$@"
      fi

      focused_workspace_id="$(
        niri msg -j focused-window 2>/dev/null \
          | jq -er '.workspace_id // empty' 2>/dev/null \
          || niri msg -j workspaces 2>/dev/null \
          | jq -er '.[] | select(.is_focused == true) | .id' 2>/dev/null \
          || true
      )"

      # Chrome cannot target a particular existing window when opening a URL.
      # Only a bare invocation reuses the Chrome window on this workspace;
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
      name = "Chrome Personal";
      exec = "${lib.getExe chromePersonal} %U";
      icon = "google-chrome";
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
      name = "Chrome Work";
      exec = "${lib.getExe chromeWork} %U";
      icon = "google-chrome";
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
    google-chrome = {
      name = "Google Chrome";
      noDisplay = true;
    };
    nignite = {
      name = "Chrome Workspace Router";
      exec = "${lib.getExe nignite} %U";
      icon = "google-chrome";
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
