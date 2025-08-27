{ ... }:
{
  programs.lazygit = {
    enable = true;
    settings = {
      gui = {
        # Use catppuccin theme colors to match the rest of the system
        theme = {
          activeBorderColor = [ "lavender" "bold" ];
          inactiveBorderColor = [ "overlay0" ];
          optionsTextColor = [ "blue" ];
          selectedLineBgColor = [ "surface0" ];
          cherryPickedCommitBgColor = [ "base" ];
          cherryPickedCommitFgColor = [ "blue" ];
          unstagedChangesColor = [ "red" ];
          defaultFgColor = [ "text" ];
        };
        showIcons = true;
      };
      git = {
        paging = {
          colorArg = "always";
          pager = "delta --dark --paging=never";
        };
        merging = {
          manualCommit = false;
          args = "";
        };
      };
      update = {
        method = "never"; # Disable auto-updates since we manage through Nix
      };
      confirmOnQuit = false;
      quitOnTopLevelReturn = true;
    };
  };
}