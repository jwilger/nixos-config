{ config, lib, ... }:
{
  # macOS wallpaper configuration
  # Uses the same wallpaper.png from the desktop module
  # but applies it using macOS-specific methods

  # Copy wallpaper to user Pictures directory
  home.file."Pictures/wallpaper.png" = {
    source = ./../desktop/wallpaper.png;
  };

  # Note: macOS wallpaper can be set via:
  # osascript -e 'tell application "Finder" to set desktop picture to POSIX file "~/Pictures/wallpaper.png"'
  # This would typically be done in an activation script

  home.activation.setWallpaper = lib.hm.dag.entryAfter ["writeBoundary"] ''
    wallpaper_path="$HOME/Pictures/wallpaper.png"
    if [ -f "$wallpaper_path" ]; then
      $DRY_RUN_CMD /usr/bin/osascript <<EOF
        tell application "System Events"
          tell every desktop
            set picture to "$wallpaper_path"
          end tell
        end tell
EOF
    fi
  '';
}
