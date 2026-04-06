{ config, lib, ... }:
{
  # macOS wallpaper configuration
  # Uses the same wallpaper.png from the desktop module
  # but applies it using macOS-specific methods

  # Copy wallpaper to user Pictures directory
  home.file."Pictures/wallpaper.png" = {
    source = ./../desktop/wallpaper.png;
  };

  # Set desktop wallpaper on macOS 14+ (Sonoma)
  # Uses osascript to set wallpaper via System Events
  # Note: We use 'run' instead of $DRY_RUN_CMD to ensure the command executes
  home.activation.setWallpaper = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    wallpaper_path="$HOME/Pictures/wallpaper.png"
    if [ -f "$wallpaper_path" ]; then
      # macOS 14 (Sonoma) requires setting the wallpaper for each display individually
      run /usr/bin/osascript -e "tell application \"System Events\" to tell every desktop to set picture to POSIX file \"$wallpaper_path\""
    fi
  '';
}
