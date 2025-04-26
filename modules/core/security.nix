{ ... }: 
{
  security.rtkit.enable = true;
  security.sudo.enable = true;
  # Require wheel users to enter their password when using sudo
  security.sudo.wheelNeedsPassword = true;
  # security.pam.services.swaylock = { };
  security.pam.services.hyprlock = {};
}
