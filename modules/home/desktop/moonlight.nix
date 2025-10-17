{ pkgs, ... }:
{
  # Moonlight game streaming client for NVIDIA GameStream and Sunshine
  home.packages = with pkgs; [
    moonlight-qt
  ];
}
