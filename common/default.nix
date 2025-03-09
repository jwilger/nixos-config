# Default imports for the system
{ ... }: 

{
  imports = [
    ../modules/system/base.nix
    ../modules/system/audio.nix
    ../modules/system/printing.nix
    ../modules/system/virtualization.nix
    ../modules/desktop/hyprland.nix
    ../modules/desktop/styling.nix
  ];
}
