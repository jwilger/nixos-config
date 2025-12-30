{ pkgs, ... }:
{
  home.packages = [ pkgs.slack ];

  xdg.desktopEntries.slack = {
    name = "Slack";
    comment = "Slack Desktop client";
    exec =
      "env NIXOS_OZONE_WL=1 ${pkgs.slack}/bin/slack --enable-features=UseOzonePlatform --ozone-platform=wayland %U";
    icon = "slack";
    terminal = false;
    type = "Application";
    categories = [ "Network" "InstantMessaging" "Office" ];
    mimeType = [
      "x-scheme-handler/slack"
      "x-scheme-handler/slack-ssb"
      "x-scheme-handler/slack-calls"
    ];
    settings = {
      StartupWMClass = "Slack";
    };
  };

  programs.zsh.shellAliases.slack =
    "NIXOS_OZONE_WL=1 ${pkgs.slack}/bin/slack --enable-features=UseOzonePlatform --ozone-platform=wayland";
}
