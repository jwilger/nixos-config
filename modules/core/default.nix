{ ... }:
{
  imports =
       [ (import ./bootloader.nix) ]
    ++ [ (import ./network.nix) ]
    ++ [ (import ./program.nix) ]
    ++ [ (import ./security.nix) ]
    ++ [ (import ./services.nix) ]
    ++ [ (import ./system.nix) ]
    ++ [ (import ./user.nix) ]
    ++ [ (import ./yubikey.nix) ];
}
