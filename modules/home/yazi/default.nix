{ pkgs, ... }:
{
  programs.yazi = {
    enable = true;
    enableZshIntegration = true;
    plugins = with pkgs.yaziPlugins; {
      git = git;
      sudo = sudo;
      glow = glow;
      rsync = rsync;
      piper = piper;
      lazygit = lazygit;
      starship = starship;
      projects = projects;
      mediainfo = mediainfo;
      toggle-pane = toggle-pane;
      time-travel = time-travel;
    };
  };

  xdg.configFile."yazi/yazi.toml".text = ''
    [mgr]
    ratio = [1, 3, 4]

    [plugin]
    prepend_previewers = [
      { name = "*.md", run = "glow" },
    ]

    [preview]
    tab_size = 2
    wrap = "yes"
  '';
}
