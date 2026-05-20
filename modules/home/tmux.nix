{ lib, pkgs, ... }:
{
  catppuccin.tmux.enable = false;

  programs.tmux = {
    enable = true;
    mouse = true;
    prefix = "C-a";
    baseIndex = 1;
    escapeTime = 0;
    historyLimit = 50000;
    keyMode = "vi";
    terminal = "tmux-256color";
    aggressiveResize = true;
    focusEvents = true;
    newSession = true;
    sensibleOnTop = true;
    shell = "${pkgs.zsh}/bin/zsh";
    tmuxinator.enable = true;

    plugins = with pkgs.tmuxPlugins; [
      yank
      pain-control
      sessionist
      {
        plugin = catppuccin;
        extraConfig = ''
          set -g @catppuccin_flavor "mocha"
          set -g @catppuccin_window_status_style "rounded"
          set -g @catppuccin_window_text " #W"
          set -g @catppuccin_window_current_text " #W"
          set -g @catppuccin_pane_status_enabled "yes"
          set -g @catppuccin_window_flags "icon"
        '';
      }
    ];

    extraConfig = ''
      # Renumber windows when one is closed
      set -g renumber-windows on

      # Status bar refresh interval
      set -g status-interval 5

      # Refresh connection-specific environment values when attaching.
      set -g update-environment "DISPLAY KRB5CCNAME MSYSTEM SSH_ASKPASS SSH_AUTH_SOCK SSH_AGENT_PID SSH_CONNECTION WINDOWID XAUTHORITY"

      # Zoom
      bind z resize-pane -Z

      # Rename window
      bind , command-prompt -I "#W" "rename-window -- '%%'"

      # Reload tmux configuration
      bind r source-file ~/.config/tmux/tmux.conf \; display-message "tmux config reloaded"

      # Keep automatic names until a window is renamed manually.
      setw -g automatic-rename on
      set -g allow-rename off

      # Next/prev window
      bind n next-window
      bind p previous-window

      # Last window
      bind i last-window

      # Close pane
      bind x kill-pane

      # Make the status line pretty and add some modules
      set -g status-right-length 100
      set -g status-left-length 100
      set -g status-left ""
      set -g @catppuccin_gitmux_text ' #(${lib.getExe pkgs.gitmux} "#{pane_current_path}")'
      set -g @catppuccin_date_time_text " %H:%M"
      set -g status-right "#{E:@catppuccin_status_gitmux}"
      set -ag status-right "#{E:@catppuccin_status_session}"
      set -ag status-right "#{E:@catppuccin_status_date_time}"
    '';
  };
}
