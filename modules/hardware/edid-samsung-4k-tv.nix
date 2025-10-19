{ pkgs, lib, ... }:

# Samsung 4K TV (75" Series 8) EDID Module
#
# This module provides EDID firmware for a virtual display simulating
# a Samsung 4K TV at 3840x2160@60Hz. This is used for headless gaming
# sessions where the actual TV is not physically connected to the GPU.
#
# The EDID data creates a virtual display connector that gamescope can
# render to, with output streamed via SteamLink to the AppleTV.

let
  # Generic 4K@60Hz EDID hex string
  # This is a minimal EDID supporting 3840x2160@60Hz with standard timings
  #
  # To obtain a specific EDID for your Samsung TV:
  # 1. Connect the TV directly to your GPU
  # 2. Extract EDID: cat /sys/class/drm/card*/card*-HDMI-A-*/edid > samsung-tv.bin
  # 3. Convert to hex: xxd -p samsung-tv.bin | tr -d '\n'
  # 4. Replace the edidHex string below
  #
  # Current EDID is a generic 4K profile suitable for most Samsung 4K TVs
  edidHex = ''
    00ffffffffffff004c2d0a0000000000
    0120010380a05a780aee91a3544c9926
    0f5054bfef80714f810081c081809500
    a9c0b3000101565e00a0a0a029503020
    350040844100001a000000fd00384b1e
    5a19000a202020202020000000fc0053
    616d73756e67205456000000000000fe
    003338343078323136304036300a0122
    020322f14b900504030201111213141f
    23090707830100006d030c002000b83c
    20006001020367d85dc401788003e305
    c000e30605018c0ad08a20e02d101030
    2c808080210000180000000000000000
    00000000000000000000000000000000
    00000000000000000000000000000000
    00000000000000000000000000000049
  '';

  # Create binary EDID file from hex string
  edidBin = pkgs.runCommand "samsung-4k-tv.bin" { } ''
    echo -n "${edidHex}" | ${pkgs.xxd}/bin/xxd -r -p > $out
  '';
in
{
  # Install EDID firmware to /lib/firmware/edid/
  hardware.firmware = [
    (pkgs.runCommand "samsung-4k-tv-edid-firmware" { } ''
      mkdir -p $out/lib/firmware/edid
      cp ${edidBin} $out/lib/firmware/edid/samsung-4k-tv.bin
    '')
  ];

  # Load EDID on Virtual-1 connector (used by headless gamescope)
  # This creates a virtual display that gamescope can render to
  boot.kernelParams = [
    "drm.edid_firmware=Virtual-1:edid/samsung-4k-tv.bin"
  ];

  # Ensure early KMS is enabled so EDID loads during boot
  boot.initrd.kernelModules = [ "amdgpu" ];
}
