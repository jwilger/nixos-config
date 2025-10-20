{ ... }:
{
  # AeroSpace tiling window manager configuration
  # AeroSpace is installed via Homebrew (see modules/darwin/homebrew.nix)
  programs.aerospace = {
    enable = true;

    settings = {
      # Start AeroSpace at login
      start-at-login = true;

      # Enable window normalizations for better tiling behavior
      enable-normalization-flatten-containers = true;
      enable-normalization-opposite-orientation-for-nested-containers = true;

      # Accordion padding for gaps between windows
      accordion-padding = 8;

      # Default layout and orientation
      default-root-container-layout = "tiles";
      default-root-container-orientation = "auto";

      # Gaps between windows
      gaps = {
        inner.horizontal = 8;
        inner.vertical = 8;
        outer.left = 8;
        outer.bottom = 8;
        outer.top = 8;
        outer.right = 8;
      };

      # Automatic workspace-to-monitor assignments
      # Workspaces 1-5 on primary monitor, 6-9 on secondary if available
      workspace-to-monitor-force-assignment = {
        "1" = "main";
        "2" = "main";
        "3" = "main";
        "4" = "main";
        "5" = "main";
      };

      # Mode definitions
      mode.main.binding = {
        # Focus navigation (alt+hjkl like vim)
        alt-h = "focus left";
        alt-j = "focus down";
        alt-k = "focus up";
        alt-l = "focus right";

        # Move windows (alt+shift+hjkl)
        alt-shift-h = "move left";
        alt-shift-j = "move down";
        alt-shift-k = "move up";
        alt-shift-l = "move right";

        # Resize mode
        alt-r = "mode resize";

        # Change layout orientation
        alt-slash = "layout tiles horizontal vertical";
        alt-comma = "layout accordion horizontal vertical";

        # Workspace switching (alt+1-9)
        alt-1 = "workspace 1";
        alt-2 = "workspace 2";
        alt-3 = "workspace 3";
        alt-4 = "workspace 4";
        alt-5 = "workspace 5";
        alt-6 = "workspace 6";
        alt-7 = "workspace 7";
        alt-8 = "workspace 8";
        alt-9 = "workspace 9";

        # Move window to workspace (alt+shift+1-9)
        alt-shift-1 = "move-node-to-workspace 1";
        alt-shift-2 = "move-node-to-workspace 2";
        alt-shift-3 = "move-node-to-workspace 3";
        alt-shift-4 = "move-node-to-workspace 4";
        alt-shift-5 = "move-node-to-workspace 5";
        alt-shift-6 = "move-node-to-workspace 6";
        alt-shift-7 = "move-node-to-workspace 7";
        alt-shift-8 = "move-node-to-workspace 8";
        alt-shift-9 = "move-node-to-workspace 9";

        # Monitor focus (alt+tab/shift+tab)
        alt-tab = "workspace-back-and-forth";
        alt-shift-tab = "move-workspace-to-monitor --wrap-around next";

        # Fullscreen toggle
        alt-f = "fullscreen";

        # Close window
        alt-shift-c = "close";

        # Balance window sizes
        alt-equal = "balance-sizes";

        # Reload AeroSpace config
        alt-shift-r = "reload-config";
      };

      # Resize mode bindings
      mode.resize.binding = {
        # Resize windows with hjkl
        h = "resize width -50";
        j = "resize height +50";
        k = "resize height -50";
        l = "resize width +50";

        # Exit resize mode
        escape = "mode main";
        enter = "mode main";
      };

      # Application-specific rules
      # Float certain applications by default
      on-window-detected = [
        {
          "if".app-id = "com.apple.systempreferences";
          run = "layout floating";
        }
        {
          "if".app-id = "com.apple.ActivityMonitor";
          run = "layout floating";
        }
        {
          "if".app-id = "com.apple.calculator";
          run = "layout floating";
        }
        {
          "if".app-id = "com.1password.1password";
          run = "layout floating";
        }
      ];
    };
  };
}
