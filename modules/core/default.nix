{ ... }:
{
  imports = [
    (import ./bootloader.nix)
  ]
  ++ [ (import ./network.nix) ]
  ++ [ (import ./printing.nix) ]
  ++ [ (import ./program.nix) ]
  ++ [ (import ./security.nix) ]
  ++ [ (import ./services.nix) ]
  ++ [ (import ./system.nix) ]
  ++ [ (import ./user.nix) ]
  ++ [ (import ./yubikey.nix) ]
  ++ [ (import ./ironclaw.nix) ];
}
