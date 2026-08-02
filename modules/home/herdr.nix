{ inputs, pkgs, ... }:
{
  home.packages = [ inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.default ];

  xdg.configFile."herdr/config.toml".text = ''
    [theme]
    name = "catppuccin-mocha"

    [keys]
    prefix = "ctrl+a"
    close_pane = "prefix+x"
    copy_mode = "prefix+["
    detach = "prefix+d"
    edit_scrollback = "prefix+e"
    focus_pane_down = "prefix+j"
    focus_pane_left = "prefix+h"
    focus_pane_right = "prefix+l"
    focus_pane_up = "prefix+k"
    last_pane = "prefix+i"
    new_tab = "prefix+c"
    next_tab = "prefix+n"
    previous_tab = "prefix+p"
    reload_config = "prefix+r"
    rename_tab = "prefix+comma"
    resize_mode = "prefix+plus"
    split_horizontal = "prefix+minus"
    split_vertical = "prefix+backslash"
    switch_tab = "prefix+1..9"
    zoom = "prefix+z"
  '';
}
