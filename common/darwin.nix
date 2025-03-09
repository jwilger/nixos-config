# Darwin (macOS) specific imports
{ ... }: 

{
  # For macOS, we'll only include base configuration
  # that's compatible with Darwin
  imports = [
    ../modules/system/darwin-base.nix
  ];
}