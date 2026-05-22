{ lib, pkgs, ... }:
{
  catppuccin.tmux.enable = false;

  home.file.".gitmux.conf".text = ''
    tmux:
        symbols:
            branch: "⎇ "
            hashprefix: ":"
            ahead: ↑·
            behind: ↓·
            staged: "● "
            conflict: "✖ "
            modified: "✚ "
            untracked: "… "
            stashed: "⚑ "
            insertions: Σ
            deletions: Δ
            clean: ✔

        styles:
            clear: ""
            state: ""
            branch: ""
            remote: ""
            divergence: ""
            staged: ""
            conflict: ""
            modified: ""
            untracked: ""
            stashed: ""
            insertions: ""
            deletions: ""
            clean: ""

        layout: [branch, remote-branch, divergence, " - ", flags]

        options:
            branch_max_len: 0
            branch_trim: right
            ellipsis: …
            hide_clean: false
            swap_divergence: false
            divergence_space: false
            flags_without_count: false
  '';

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
      # so that shift-enter works in agent CLIs
      set -g extended-keys on
      set -g extended-keys-format csi-u

      # Renumber windows when one is closed
      set -g renumber-windows on

      # Status bar refresh interval
      set -g status-interval 5

      # Keep SSH agent access stable across local and remote attaches.
      set-environment -g SSH_AUTH_SOCK "$HOME/.ssh/ssh_auth_sock"

      # Refresh connection-specific environment values when attaching.
      set -g update-environment "DISPLAY KRB5CCNAME MSYSTEM SSH_ASKPASS SSH_AGENT_PID SSH_CONNECTION WINDOWID XAUTHORITY"

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
      set -g @catppuccin_gitmux_text ' #(${lib.getExe pkgs.gitmux} -cfg "$HOME/.gitmux.conf" "#{pane_current_path}" | ${lib.getExe pkgs.gnused} "s/#\[fg=default,bg=default\]\$//")'
      set -g @catppuccin_date_time_text " %H:%M"
      set -g status-right "#{E:@catppuccin_status_gitmux}"
      set -ag status-right "#{E:@catppuccin_status_session}"
      set -ag status-right "#{E:@catppuccin_status_date_time}"
    '';
  };
}
