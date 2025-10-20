{ pkgs, lib, ... }:
let
  # Catppuccin Mocha color scheme for iTerm2
  # Colors from https://github.com/catppuccin/iterm
  catppuccinMocha = {
    # Base colors
    background = { r = 0.117647; g = 0.117647; b = 0.156863; }; # base
    foreground = { r = 0.803922; g = 0.815686; b = 0.878431; }; # text

    # ANSI colors
    ansi0 = { r = 0.282353; g = 0.290196; b = 0.368627; }; # surface1
    ansi1 = { r = 0.945098; g = 0.541176; b = 0.658824; }; # red
    ansi2 = { r = 0.647059; g = 0.886275; b = 0.662745; }; # green
    ansi3 = { r = 0.976471; g = 0.878431; b = 0.470588; }; # yellow
    ansi4 = { r = 0.541176; g = 0.690196; b = 0.972549; }; # blue
    ansi5 = { r = 0.945098; g = 0.694118; b = 0.980392; }; # pink
    ansi6 = { r = 0.564706; g = 0.898039; b = 0.901961; }; # teal
    ansi7 = { r = 0.717647; g = 0.737255; b = 0.819608; }; # subtext1

    # Bright ANSI colors
    ansi8 = { r = 0.364706; g = 0.376471; b = 0.470588; }; # surface2
    ansi9 = { r = 0.945098; g = 0.541176; b = 0.658824; }; # red
    ansi10 = { r = 0.647059; g = 0.886275; b = 0.662745; }; # green
    ansi11 = { r = 0.976471; g = 0.878431; b = 0.470588; }; # yellow
    ansi12 = { r = 0.541176; g = 0.690196; b = 0.972549; }; # blue
    ansi13 = { r = 0.945098; g = 0.694118; b = 0.980392; }; # pink
    ansi14 = { r = 0.564706; g = 0.898039; b = 0.901961; }; # teal
    ansi15 = { r = 0.913725; g = 0.921569; b = 0.956863; }; # subtext0

    # Selection colors
    selection = { r = 0.364706; g = 0.376471; b = 0.470588; }; # surface2
    selectionText = { r = 0.803922; g = 0.815686; b = 0.878431; }; # text

    # Cursor colors
    cursor = { r = 0.956863; g = 0.894118; b = 0.890196; }; # rosewater
    cursorText = { r = 0.117647; g = 0.117647; b = 0.156863; }; # base
  };

  # Helper function to create color dict for plist
  mkColor = color: {
    "Alpha Component" = 1.0;
    "Blue Component" = color.b;
    "Color Space" = "sRGB";
    "Green Component" = color.g;
    "Red Component" = color.r;
  };
in
{
  # iTerm2 shell integration
  programs.iterm2 = {
    enable = true;
    enableZshIntegration = true;
  };

  # Deploy iTerm2 configuration as plist
  # This creates a preferences file that iTerm2 will use automatically
  home.file."Library/Preferences/com.googlecode.iterm2.plist" = {
    source = pkgs.writeText "com.googlecode.iterm2.plist" (lib.generators.toPlist {} {
      # Window and appearance settings
      "Default Bookmark Guid" = "Default";
      "New Bookmarks" = [
        {
          # Profile settings
          "Name" = "Default";
          "Guid" = "Default";
          "Custom Directory" = "No";

          # Font configuration
          "Normal Font" = "JetBrainsMonoNFM-Regular 15";
          "Non Ascii Font" = "Monaco 12";
          "Use Non-ASCII Font" = false;
          "ASCII Ligatures" = true;
          "ASCII Anti Aliased" = true;
          "Non-ASCII Anti Aliased" = true;

          # Catppuccin Mocha colors
          "Background Color" = mkColor catppuccinMocha.background;
          "Foreground Color" = mkColor catppuccinMocha.foreground;

          "Ansi 0 Color" = mkColor catppuccinMocha.ansi0;
          "Ansi 1 Color" = mkColor catppuccinMocha.ansi1;
          "Ansi 2 Color" = mkColor catppuccinMocha.ansi2;
          "Ansi 3 Color" = mkColor catppuccinMocha.ansi3;
          "Ansi 4 Color" = mkColor catppuccinMocha.ansi4;
          "Ansi 5 Color" = mkColor catppuccinMocha.ansi5;
          "Ansi 6 Color" = mkColor catppuccinMocha.ansi6;
          "Ansi 7 Color" = mkColor catppuccinMocha.ansi7;
          "Ansi 8 Color" = mkColor catppuccinMocha.ansi8;
          "Ansi 9 Color" = mkColor catppuccinMocha.ansi9;
          "Ansi 10 Color" = mkColor catppuccinMocha.ansi10;
          "Ansi 11 Color" = mkColor catppuccinMocha.ansi11;
          "Ansi 12 Color" = mkColor catppuccinMocha.ansi12;
          "Ansi 13 Color" = mkColor catppuccinMocha.ansi13;
          "Ansi 14 Color" = mkColor catppuccinMocha.ansi14;
          "Ansi 15 Color" = mkColor catppuccinMocha.ansi15;

          "Selection Color" = mkColor catppuccinMocha.selection;
          "Selected Text Color" = mkColor catppuccinMocha.selectionText;
          "Cursor Color" = mkColor catppuccinMocha.cursor;
          "Cursor Text Color" = mkColor catppuccinMocha.cursorText;

          # Terminal behavior
          "Option Key Sends" = 0;
          "Right Option Key Sends" = 0;
          "Rows" = 25;
          "Columns" = 80;
          "Scrollback Lines" = 10000;
          "Unlimited Scrollback" = false;

          # Visual settings
          "Transparency" = 0;
          "Blur" = false;
          "Blur Radius" = 2.0;
          "Use Bold Font" = true;
          "Use Italic Font" = true;
          "Ambiguous Double Width" = false;

          # Window behavior
          "Close Sessions On End" = true;
          "Silence Bell" = false;
          "Visual Bell" = true;

          # Working directory
          "Custom Directory" = "Recycle";
        }
      ];

      # Global iTerm2 preferences
      "AppleSmoothFixedFontsSizeThreshold" = 1;
      "AdjustWindowForFontSizeChange" = true;
      "PrefsCustomFolder" = "~/.config/iterm2";
      "LoadPrefsFromCustomFolder" = false;

      # Update checking
      "SUEnableAutomaticChecks" = true;
      "SUHasLaunchedBefore" = true;
    });
  };

  # Ensure iTerm2 config directory exists
  home.file.".config/iterm2/.keep".text = "# iTerm2 configuration directory";
}
