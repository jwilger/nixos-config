{ ... }:
{
  programs.kitty = {
    enable = true;

    themeFile = "Catppuccin-Mocha";

    font = {
      # Use the mono-patched family name exposed by nerd-fonts.jetbrains-mono
      name = "JetBrainsMono Nerd Font Mono";
      size = 11;
    };

    settings = {
      confirm_os_window_close = 0;
      background_opacity = "0.85";
      window_padding_width = 0;
      scrollback_lines = 10000;
      enable_audio_bell = false;
      mouse_hide_wait = 60;
      hide_window_decorations = "yes";
      window_border_width = 0;
      draw_minimal_borders = "yes";
      disable_ligatures = "never"; # keep JetBrains Mono ligatures enabled
      font_features = "JetBrainsMono Nerd Font Mono +liga +calt +dlig";

      ## Tabs
      tab_title_template = "{index}";
      active_tab_font_style = "normal";
      inactive_tab_font_style = "normal";
      tab_bar_style = "powerline";
      tab_powerline_style = "round";
      active_tab_foreground = "#1e1e2e";
      active_tab_background = "#cba6f7";
      inactive_tab_foreground = "#bac2de";
      inactive_tab_background = "#313244";
    };

    keybindings = {
      ## Tabs
      "alt+1" = "goto_tab 1";
      "alt+2" = "goto_tab 2";
      "alt+3" = "goto_tab 3";
      "alt+4" = "goto_tab 4";

      ## Multi-line prompt
      "shift+enter" = "send_text all \\n";

      ## New window in current directory
      "super+shift+n" = "new_os_window_with_cwd";

      ## Unbind
      "ctrl+shift+left" = "no_op";
      "ctrl+shift+right" = "no_op";
    };
  };
}
