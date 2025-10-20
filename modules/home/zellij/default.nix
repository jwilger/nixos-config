{ pkgs, config, ... }:
let
  # Create a derivation for zjstatus plugin
  zjstatus = pkgs.stdenvNoCC.mkDerivation rec {
    pname = "zjstatus";
    version = "0.21.1";

    src = pkgs.fetchurl {
      url = "https://github.com/dj95/zjstatus/releases/download/v${version}/zjstatus.wasm";
      sha256 = "sha256-3BmCogjCf2aHHmmBFFj7savbFeKGYv3bE2tXXWVkrho=";
    };

    dontUnpack = true;

    installPhase = ''
      mkdir -p $out
      cp $src $out/zjstatus.wasm
    '';
  };
in
{
  home.packages = with pkgs; [
    zellij
  ];

  xdg.configFile."zellij/config.kdl".source = ./config.kdl;

  # Create the layout file using writeText to avoid duplication bug
  xdg.configFile."zellij/layouts/compact-with-datetime.kdl".source = pkgs.writeText "zellij-layout-compact-with-datetime.kdl" ''
    layout {
        default_tab_template {
            children
            pane size=1 borderless=true {
                plugin location="file://${zjstatus}/zjstatus.wasm" {
                    // Main status bar configuration
                    format_left   "{mode} #[fg=#B4BEFE,bg=#1E1E2E,bold]  {session} #[fg=#313244,bg=#1E1E2E]  {tabs}"
                    format_center ""
                    format_right  "{datetime}"

                    // Mode colors - Catppuccin Mocha theme with icons
                    mode_normal          "#[bg=#89B4FA,fg=#1E1E2E,bold]  "
                    mode_locked          "#[bg=#F9E2AF,fg=#1E1E2E,bold]  "
                    mode_resize          "#[bg=#F38BA8,fg=#1E1E2E,bold]  "
                    mode_pane            "#[bg=#A6E3A1,fg=#1E1E2E,bold]  "
                    mode_tab             "#[bg=#CBA6F7,fg=#1E1E2E,bold]  "
                    mode_scroll          "#[bg=#94E2D5,fg=#1E1E2E,bold]  "
                    mode_enter_search    "#[bg=#F5C2E7,fg=#1E1E2E,bold]  "
                    mode_search          "#[bg=#F5C2E7,fg=#1E1E2E,bold]  "
                    mode_rename_tab      "#[bg=#FAB387,fg=#1E1E2E,bold]  "
                    mode_rename_pane     "#[bg=#FAB387,fg=#1E1E2E,bold]  "
                    mode_session         "#[bg=#74C7EC,fg=#1E1E2E,bold]  "
                    mode_move            "#[bg=#F2CDCD,fg=#1E1E2E,bold]  "
                    mode_prompt          "#[bg=#CDD6F4,fg=#1E1E2E,bold]  "
                    mode_tmux            "#[bg=#F38BA8,fg=#1E1E2E,bold]  "

                    // Tab styles - Powerline-inspired with rounded edges
                    tab_normal              "#[fg=#313244,bg=#1E1E2E]#[fg=#6C7086,bg=#313244] {index} #[fg=#585B70]#[fg=#9399B2] {name} #[fg=#313244,bg=#1E1E2E]"
                    tab_active              "#[fg=#45475A,bg=#1E1E2E,bold]#[fg=#89B4FA,bg=#45475A] {index} #[fg=#CDD6F4]#[fg=#F5E8E4,bold] {name} #[fg=#45475A,bg=#1E1E2E,bold]"
                    tab_fullscreen_indicator       " "
                    tab_sync_indicator              " "
                    tab_floating_indicator          " "

                    // DateTime configuration
                    datetime          "#[fg=#313244,bg=#1E1E2E]#[fg=#9399B2,bg=#313244]  {format} #[fg=#313244,bg=#1E1E2E]"
                    datetime_format   "%a %d %b  %H:%M"
                    datetime_timezone "America/Los_Angeles"

                    // Other settings
                    hide_frame_for_single_pane "true"
                    border_enabled "false"
                }
            }
        }
    }
  '';

  # Zellij-specific shell aliases
  programs.zsh.shellAliases = {
    # Attach or create session named after current directory
    zz = ''
      ${pkgs.zellij}/bin/zellij --layout=.zellij.kdl attach -c "`basename \"$PWD\"`"
    '';

    # Attach to first available session
    za = ''
      ${pkgs.zellij}/bin/zellij attach --index 0
    '';
  };
}
