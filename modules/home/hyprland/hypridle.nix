{...}:
{
  services.hypridle = {
    enable = true;
    settings = {
      after_sleep_cmd = "hyprctl dispatch dpms on";
      ignore_dbus_inhibit = false;
      lock_cmd = "1password --lock & pidof hyprlock || hyprlock";
      listener = [
        {
          timeout = 900;
          on-timeout="1password --lock & pidof hyprlock || hyprlock";
        }
        {
          timeout = 1200;
          on-timeout = "hyprctl dispatch dpms off";
          on-resume = "hyprctl dispatch dpms on";
        }
      ];
    };
  };
}
