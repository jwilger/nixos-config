{ pkgs, ... }:
{
  home.packages = [ pkgs.slack ];

  xdg.desktopEntries.slack = {
    name = "Slack";
    comment = "Slack Desktop client";
    exec =
      "env NIXOS_OZONE_WL=1 ${pkgs.slack}/bin/slack %U";
    icon = "slack";
    terminal = false;
    type = "Application";
    categories = [ "Network" "InstantMessaging" "Office" ];
    startupWMClass = "Slack";
    mimeType = [
      "x-scheme-handler/slack"
      "x-scheme-handler/slack-ssb"
      "x-scheme-handler/slack-calls"
    ];
  };

  programs.zsh.shellAliases.slack =
    "NIXOS_OZONE_WL=1 ${pkgs.slack}/bin/slack";
}
