{ pkgs, ... }:
let
  # Catppuccin Mocha palette (matching zellij zjstatus bar)
  base = "#1e1e2e";
  surface0 = "#313244";
  lavender = "#cba6f7";
  blue = "#89B4FA";
  text = "#cdd6f4";
in
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

    extraConfig = ''
      # True color support
      set -ag terminal-overrides ",xterm-256color:RGB"

      # Renumber windows when one is closed
      set -g renumber-windows on

      # Status bar refresh interval
      set -g status-interval 5

      # --- Status bar styling (matching zellij zjstatus) ---
      set -g status-style "bg=${base},fg=${text}"
      set -g status-left-length 40
      set -g status-right-length 120

      # Left: session name on blue background with powerline separator
      set -g status-left "#[fg=${base},bg=${blue},bold] #S #[fg=${blue},bg=${base}]"

      # Window (tab) list
      set -g window-status-format "#[fg=${base},bg=${surface0}]#[fg=${text},bg=${surface0}] #I  #W #[fg=${surface0},bg=${base}]"
      set -g window-status-current-format "#[fg=${base},bg=${lavender}]#[fg=${base},bg=${lavender},bold,italics] #I  #W #[fg=${lavender},bg=${base}]"
      set -g window-status-separator ""

      # Right: pwd, git branch, datetime on blue
      set -g status-right "#[fg=${text},bg=${base}] #{pane_current_path} #[fg=${lavender},bg=${base}] #(cd #{pane_current_path} && git rev-parse --abbrev-ref HEAD 2>/dev/null) #[fg=${blue},bg=${base}]#[fg=${base},bg=${blue},bold] %A, %d %b %Y %H:%M "

      # Pane borders
      set -g pane-border-style "fg=${surface0}"
      set -g pane-active-border-style "fg=${lavender}"

      # Message styling
      set -g message-style "fg=${base},bg=${lavender},bold"

      # --- Keybindings (matching zellij tmux-mode) ---

      # Splits (inherit current directory)
      bind \\ split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"

      # Pane navigation (vim-style)
      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R

      # Zoom
      bind z resize-pane -Z

      # New window (inherit current directory)
      bind c new-window -c "#{pane_current_path}"

      # Rename window
      bind , command-prompt -I "#W" "rename-window -- '%%'"

      # Next/prev window
      bind n next-window
      bind p previous-window

      # Last window
      bind i last-window

      # Close pane
      bind x kill-pane

      # Copy mode
      bind [ copy-mode

      # Lazygit popup
      bind g display-popup -d "#{pane_current_path}" -w 90% -h 90% -E "lazygit"

      # Send literal C-a
      bind C-a send-prefix
    '';
  };
}
