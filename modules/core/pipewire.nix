{ pkgs, ... }: 
{
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    # enable PulseAudio compatibility layer via PipeWire
    pulse.enable = true;
    # ensure the modern PipeWire session manager is running
    wireplumber.enable = true;
  };
  environment.systemPackages = with pkgs; [
    pulseaudioFull
  ];
}
