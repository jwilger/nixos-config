{ ... }: 
{
  security.rtkit.enable = true;
  security.sudo.enable = true;
  security.sudo.wheelNeedsPassword = true;
  security.pam.services.hyprlock = {
    enable = true;
  };
}
