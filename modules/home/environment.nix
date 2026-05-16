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
    MICRO_TRUECOLOR = "1";
    EDITOR = "hx";
    VISUAL = "hx";
    NIXOS_OZONE_WL = "1";
    ELECTRON_OZONE_PLATFORM_HINT = "auto";
    NPM_CONFIG_PREFIX = npmPrefix;
    NODE_PATH = "${npmPrefix}/lib/node_modules";
    PYTHONUSERBASE = "${config.home.homeDirectory}/.local";

    # All Rust build output goes into the ~/.build subvolume, which is
    # excluded from the btrbk snapshots (see modules/core/btrfs-snapshots.nix).
    # Cargo namespaces builds per-package under here, so a single shared
    # target dir works across every project.
    CARGO_TARGET_DIR = "${config.home.homeDirectory}/.build/cargo";
  };

  home.sessionPath = [
    "$HOME/.local/bin"
    "$HOME/.cargo/bin"
    "${npmPrefix}/bin"
  ];

  home.file."${npmDir}/.keep".text = "";
}
