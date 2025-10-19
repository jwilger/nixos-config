{ pkgs, lib, ... }:

# Apple Studio Display EDID Module
#
# This module provides EDID firmware override for the Apple Studio Display
# connected via DisplayPort (DP-3). This ensures proper resolution and
# refresh rate detection, particularly useful if automatic detection fails.
#
# The Apple Studio Display is a 27" 5K (5120x2880) display with 60Hz refresh.

let
  # Apple Studio Display EDID hex string
  # Resolution: 5120x2880 @ 60Hz
  edidHex = ''
    00ffffffffffff0006103aae0be3ae3d07200104c53c2178000f91ae5243b0260f505400000001010101010101010101010101010101b7ce0050f0705a800820c800534f2100001ad05c0050a0a03c500820e808534f2100001abc34805070382d400820f804534f2100001a000000fc0053747564696f446973706c617903b102030f80e3050000e606010173730070bc0078a04078b00820a80800000000001a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000127012790000290010a1043fa85ac84e3880d4ff9e88e0f40701000c4017140d0014400b10784ebb7f81070010fa0401000012001682100000ff093f0b00000000004150503bae0be3ae3d7e00053a029281007e00100010fa0501010060c0d2ff550010001000000000000000000000000000000000000000000000000000a39070127900000300149f6d0184ff134f0007801f003f0b77006900070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000009590
  '';

  # Create binary EDID file from hex string
  edidBin = pkgs.runCommand "apple-studio-display.bin" { } ''
    echo -n "${edidHex}" | ${pkgs.xxd}/bin/xxd -r -p > $out
  '';
in
{
  # Install EDID firmware to /lib/firmware/edid/
  hardware.firmware = [
    (pkgs.runCommand "apple-studio-display-edid-firmware" { } ''
      mkdir -p $out/lib/firmware/edid
      cp ${edidBin} $out/lib/firmware/edid/apple-studio-display.bin
    '')
  ];

  # Load EDID on DP-3 connector (Apple Studio Display connection)
  # This overrides any problematic EDID data from the display itself
  boot.kernelParams = [
    "drm.edid_firmware=DP-3:edid/apple-studio-display.bin"
  ];

  # Ensure early KMS is enabled so EDID loads during boot
  boot.initrd.kernelModules = [ "amdgpu" ];
}
