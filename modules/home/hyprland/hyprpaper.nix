{ ... }:
{
  services.hyprpaper = {
    enable = true;
    settings = {
      ipc = "on";
      splash = false;
      preload = "${./wallpaper.png}";
      wallpaper = ",${./wallpaper.png}";
    };
  };
}
