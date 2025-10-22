{
  config,
  ...
}:
let
  npmDir = ".local/share/npm";
  npmPrefix = "${config.home.homeDirectory}/${npmDir}";
in
{
  xdg.enable = true;

  home.sessionVariables = {
    SSH_AUTH_SOCK = "${config.home.homeDirectory}/.1password/agent.sock";
    MICRO_TRUECOLOR = "1";
    EDITOR = "nvim";
    VISUAL = "nvim";
    NIXOS_OZONE_WL = "1";
    ELECTRON_OZONE_PLATFORM_HINT = "auto";
    NPM_CONFIG_PREFIX = npmPrefix;
    NODE_PATH = "${npmPrefix}/lib/node_modules";
  };

  home.sessionPath = [
    "$HOME/.local/bin"
    "${npmPrefix}/bin"
  ];

  home.file."${npmDir}/.keep".text = "";
}
