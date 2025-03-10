# Desktop configuration for jwilger user
{ pkgs, lib, ... }: 

{
  # Import the base configuration
  imports = [ ./base.nix ];

  fonts.fontconfig.enable = true;

  stylix = {
    enable = true;
    image = ./../../cat-sound.png;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-macchiato.yaml";
    polarity = "dark";
    targets = {
      hyprlock.enable = false;
      neovim.enable = false;
      helix.enable = false;
    };
  };

  home = {
    pointerCursor.hyprcursor.enable = true;

    # Desktop-specific packages
    packages = with pkgs; [
      thunderbird
      clockify
      dwt1-shell-color-scripts
      nautilus
      pavucontrol
      hyprpolkitagent
      spotify
      hyprcursor
      swaynotificationcenter
      wl-clipboard
      libnotify
      slack
    ];
  };

  # Desktop-specific services
  services = {
    hypridle = {
      enable = true;
      settings = {
        general = {
          after_sleep_cmd = "hyprctl dispatch dpms on";
          ignore_dbus_inhibit = false;
          lock_cmd = "pidof hyprlock || hyprlock";
        };
        listener = [
        {
          timeout = 200;
          on-timeout = "pidof hyprlock || hyprlock";
        }
        {
          timeout = 600;
          on-timeout = "hyprctl dispatch dpms off";
          on-resume = "hyprctl dispatch dpms on";
        }
        ];
      };
    };

    hyprpaper = {
      enable = true;
      settings = {
        ipc = "on";
        splash = false;
      };
    };

    swaync = {
      enable = true;
    };
  };

  # Desktop-specific programs
  programs = {
    sioyek.enable = true;
    obs-studio.enable = true;
    
    waybar = {
      enable = true;
      style = ''
        * {
          font-size: 16;
          font-family: "JetBrainsMono Nerd Font";
        }
      '';
      settings = {
        mainBar = {
          layer = "top";
          position = "bottom";
          height = 36;
          margin-top = 5;
          mode = "dock";
          spacing = 20;

          modules-left = [
            "hyprland/workspaces"
            "hyprland/submap"
          ];
          modules-center = [
          ];
          modules-right = [
            "idle_inhibitor"
            "cpu"
            "memory"
            "disk"
            "wireplumber"
            "custom/notification"
            "tray"
            "clock"
          ];

          idle_inhibitor = {
            format = "{icon}";
            format-icons = {
              activated = "";
              deactivated = "";
            };
          };

          cpu = {
            format = "󰻠 {usage}%";
          };

          memory = {
            format = " {percentage}%";
          };

          disk = {
            format = " {percentage_used}%";
          };

          wireplumber = {
            format = " {volume}%";
            format-muted = " {volume}%";
            max-volume = 100;
            on-click = "${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_SINK@ toggle";
            on-click-right = "${pkgs.pavucontrol}/bin/pavucontrol";
          };

          clock = {
            format = " {:%H:%M}";
            format-alt = " {:%A, %B %d, %Y (%R)}";
            tooltip-format = "<tt><small>{calendar}</small></tt>";
            calendar = {
              mode = "year";
              mode-mon-col = 3;
              weeks-pos = "right";
              on-scroll = 1;
              format = {
                months = "<span color='#ffead3'><b>{}</b></span>";
                days = "<span color='#ecc69d'><b>{}</b></span>";
                weeks = "<span color='#99ffdd'><b>{}</b></span>";
                weedays = "<span color='#ffcc66'><b>{}</b></span>";
                today = "<span color='#ff6699'><b>{}</b></span>";
              };
            };
            actions = {
              on-click-right = "mode";
              on-click-forward = "tz_up";
              on-click-backward = "tz_down";
              on-scroll-up = "shift_up";
              on-scroll-down = "shift_down";
            };
          };

          "hyprland/workspaces" = {
            format = "{icon}";
          };

          "custom/notification" = {
            "tooltip" = false;
            "format" = "{icon} ";
            "format-icons" = {
              "notification" = " <span foreground='red'><sup></sup></span>";
              "none" = " ";
              "dnd-notification" = " <span foreground='red'><sup></sup></span>";
              "dnd-none" = "";
              "inhibited-notification" = " <span foreground='red'><sup></sup></span>";
              "inhibited-none" = "";
              "dnd-inhibited-notification" = " <span foreground='red'><sup></sup></span>";
              "dnd-inhibited-none" = "";
            };
            "return-type" = "json";
            "exec-if" = "which swaync-client";
            "exec" = "swaync-client -swb";
            "on-click" = "swaync-client -t -sw";
            "on-click-right" = "swaync-client -d -sw";
            "escape" = true;
          };

          tray = {
            show-passive-items = true;
            spacing = 10;
            icon-size = 21;
          };
        };
      };
    };
    
    hyprlock = {
      enable = true;
      settings = {
        background = {
          path = "${./../../cat-sound.png}";
          blur_passes = 2;
          contrast = 1;
          brightness = 0.5;
          vibrancy = 0.2;
          vibrancy_darkness = 0.2;
        };

        general = {
          no_fade_in = false;
          no_fade_out = false;
          hide_cursor = false;
          grace = 10;
          disable_loading_bar = true;
        };

        input-field = {
          size = "800, 60";
          outline_thickness = 3;
          dots_size = 0.2; # Scale of input-field height, 0.2 - 0.8
          dots_spacing = 0.35; # Scale of dots' absolute size, 0.0 - 1.0
          dots_center = true;
          # outer_color = "rgba(0, 0, 0, 0.8)";
          # inner_color = "rgba(0, 0, 0, 0.0)";
          # font_color = "rgb(255,255,255)";
          fade_on_empty = false;
          rounding = -1;
          # check_color = "rgb(204, 136, 34)";
          placeholder_text = "<i>YOU SHALL NOT PASS...unless you have the right password, man.</i>";
          hide_input = false;
          position = "0, -200";
          halign = "center";
          valign = "center";
        };

        label = [
          {
            text = ''
              cmd[update:1000] echo "$(date +"%A, %B %d")"
            '';
            color = "rgba (242, 243, 244, 0.75)";
            font_size = 22;
            font_family = "JetBrainsMono Nerd Font";
            position = "0, 300";
            halign = "center";
            valign = "center";
          }
          {
            text = ''
              cmd[update:1000] echo "$(date +"%A, %B %d")"
            '';
            color = "rgba(242, 243, 244, 0.75)";
            font_size = 22;
            font_family = "JetBrainsMono Nerd Font";
            position = "0, 300";
            halign = "center";
            valign = "center";
          }
          {
            text = ''
              cmd[update:1000] echo "$(date +"%A, %B %d")"
            '';
            color = "rgba(242, 243, 244, 0.75)";
            font_size = 22;
            font_family = "JetBrainsMono Nerd Font";
            position = "0, 300";
            halign = "center";
            valign = "center";
          }

          {
            text = ''
              cmd[update:1000] echo "$(date +"%-I:%M")"
            '';
            color = "rgba(242, 243, 244, 0.75)";
            font_size = 95;
            font_family = "JetBrainsMono Nerd Font Extrabold";
            position = "0, 200";
            halign = "center";
            valign = "center";
          }
        ];

        image = [
          {
            path = "${./../../profile-picture.jpg}";
            size = 400;
            border_size = 2;
            border_color = "#cdd6f4";
            position = "0, -100";
            halign = "center";
            valign = "center";
          }
        ];
      };
    };

    kitty = {
      enable = true;
      font = {
        name = lib.mkForce "JetBrainsMono Nerd Font";
        size = lib.mkForce 10.0;
      };
      settings = {
        draw_minimal_borders = "yes";
        hide_window_decorations = "yes";
      };
    };

    helix = {
      enable = true;
      defaultEditor = false;
      settings = {
        theme = "catppuccin_macchiato";
        editor = {
          true-color = true;
          scrolloff = 10;
          shell = ["zsh" "-c"];
          cursorline = true;
          preview-completion-insert = false;
          completion-trigger-len = 3;
          auto-info = true;
          bufferline = "never";
          popup-border = "all";
          lsp = {
            display-messages = true;
            display-inlay-hints = true;
          };
          cursor-shape = {
            normal = "block";
            insert = "bar";
            select = "underline";
          };
          indent-guides = {
            render = true;
          };
          end-of-line-diagnostics = "hint";
          inline-diagnostics = {
            cursor-line = "warning";
          };
        };
        keys = {
          normal = {
            "C-s" = ":w";
          };
          insert = {
            "C-s" = ["normal_mode" ":w"];
          };
        };
      };
      languages = {
        language = [
          {
            name = "elixir";
            scope = "source.elixir";
            auto-format = true;
            language-servers = ["nextls"];
          }
          {
            name = "heex";
            scope = "source.elixir";
            auto-format = true;
            language-servers = ["nextls" "elixir-ls"];
          }
        ];
        language-server = {
          nextls = {
            command = "next_ls_1_18_1_otp27";
            args = ["--stdio=true"];
            configuration = {
              extensions = {
                credo = {
                  enable = true;
                };
              };
              experimental = {
                completions = {
                  enable = true;
                };
              };
            };
          };
          elixir-ls = {
            command = "elixir-ls";
            configuration = {
              dialyzerEnabled = true;
              enableTestLenses = true;
            };
          };
        };
      };
    };

    wlogout.enable = true;
    fuzzel = {
      enable = true;
      settings.main = {
        layer = "overlay";
        terminal = "${pkgs.kitty}/bin/kitty";
        width = 40;
      };
    };
    lf = {
      enable = true;
    };
  };

  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;

    settings = {
      exec-once = [
        "uwsm app -- ${pkgs.waybar}/bin/waybar"
        "uwsm app -- ${pkgs._1password-gui}/bin/1password --silent"
        "uwsm app -- ${pkgs.solaar}/bin/solaar -w hide"
        "uwsm app -- ${pkgs.clockify}/bin/clockify"
      ];
      monitor = ",preferred,auto,auto";
      "$terminal" = "uwsm app -- kitty";
      general = {
        border_size = 1;
        gaps_in = 3;
        gaps_out = 0;
        layout = "dwindle";
      };
      decoration = {
        rounding = 10;
        active_opacity = 0.98;
        inactive_opacity = 0.8;
        dim_inactive = false;
        blur = {
          enabled = true;
          special = true;
          popups = true;
          passes = 2;
          size = 16;
        };
      };
      dwindle = {
        pseudotile = true;
        preserve_split = true;
        # no_gaps_when_only = true;
      };
      master = {
        new_status = "master";
        # no_gaps_when_only = true;
      };
      misc = {
        font_family = "JetBrainsMono Nerd Font";
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
        mouse_move_enables_dpms = true;
        key_press_enables_dpms = true;
        focus_on_activate = true;
      };
      cursor = {
        inactive_timeout = 10;
        hide_on_key_press = true;
      };
      input = {
        follow_mouse = 2;
      };

      windowrulev2 = "suppressevent maximize, class:.*";
    };

    extraConfig = ''
      env = NIXOS_OZONE_WL, 1
      env = XDG_CURRENT_DESKTOP, Hyprland
      env = XDG_SESSION_TYPE, wayland
      env = XDG_SESSION_DESKTOP, Hyprland
      env = GDK_BACKEND, wayland, x11
      env = CLUTTER_BACKEND, wayland
      env = QT_QPA_PLATFORM=wayland;xcb
      env = QT_WAYLAND_DISABLE_WINDOWDECORATION, 1
      env = QT_AUTO_SCREEN_SCALE_FACTOR, 1
      env = SDL_VIDEODRIVER, x11
      env = MOZ_ENABLE_WAYLAND, 1
      
      $mainMod = SUPER
      $terminal = uwsm app -- ${pkgs.kitty}/bin/kitty
      $menu = uwsm app -- ${pkgs.fuzzel}/bin/fuzzel --launch-prefix="uwsm app -- "
      $logout = ${pkgs.wlogout}/bin/wlogout
      $browser = uwsm app -- ${pkgs.firefox}/bin/firefox
      $filemanager = $terminal
      bind = $mainMod SHIFT,Q,exec,${pkgs.wlogout}/bin/wlogout
      bind = $mainMod, T,exec,$terminal
      bind = $mainMod, B, exec,$browser
      bind = $mainMod, C, killactive,
      bind = $mainMod, E, exec, $fileManager
      bind = $mainMod, F, togglefloating,
      bind = $mainMod, RETURN, fullscreen
      bind = $mainMod, G, togglegroup,
      bind = $mainMod, SPACE, exec, $menu
      bind = $mainMod, P, pseudo,
      bind = $mainMod SHIFT, T, togglesplit,
      bind = $mainMod, H, movefocus, l
      bind = $mainMod, L, movefocus, r
      bind = $mainMod, K, movefocus, u
      bind = $mainMod, J, movefocus, d
      bind = $mainMod CONTROL, J, changegroupactive, f
      bind = $mainMod CONTROL, K, changegroupactive, b
      bind = $mainMod SHIFT, h, movewindoworgroup, l
      bind = $mainMod SHIFT, j, movewindoworgroup, d
      bind = $mainMod SHIFT, k, movewindoworgroup, u
      bind = $mainMod SHIFT, l, movewindoworgroup, r
      bind = $mainMod, 1, workspace, 1
      bind = $mainMod, 2, workspace, 2
      bind = $mainMod, 3, workspace, 3
      bind = $mainMod, 4, workspace, 4
      bind = $mainMod, 5, workspace, 5
      bind = $mainMod, 6, workspace, 6
      bind = $mainMod, 7, workspace, 7
      bind = $mainMod, 8, workspace, 8
      bind = $mainMod, 9, workspace, 9
      bind = $mainMod, 0, workspace, 10
      bind = $mainMod SHIFT, 1, movetoworkspace, 1
      bind = $mainMod SHIFT, 2, movetoworkspace, 2
      bind = $mainMod SHIFT, 3, movetoworkspace, 3
      bind = $mainMod SHIFT, 4, movetoworkspace, 4
      bind = $mainMod SHIFT, 5, movetoworkspace, 5
      bind = $mainMod SHIFT, 6, movetoworkspace, 6
      bind = $mainMod SHIFT, 7, movetoworkspace, 7
      bind = $mainMod SHIFT, 8, movetoworkspace, 8
      bind = $mainMod SHIFT, 9, movetoworkspace, 9
      bind = $mainMod SHIFT, 0, movetoworkspace, 10
      bind = $mainMod, S, togglespecialworkspace, magic
      bind = $mainMod SHIFT, S, movetoworkspace, special:magic
      bind = $mainMod, mouse_down, workspace, e+1
      bind = $mainMod, mouse_up, workspace, e-1
      bindm = $mainMod, mouse:272, movewindow
      bindm = $mainMod, mouse:273, resizewindow

      bind = $mainMod,R,submap,resize
      submap=resize
      binde=,l,resizeactive,10 0
      binde=,h,resizeactive,-10 0
      binde=,k,resizeactive,0 -10
      binde=,j,resizeactive,0 10
      bind=,ESCAPE,submap,reset
      bind=,RETURN,submap,reset
      bind=,catchall,submap,reset
      submap=reset
    '';
  };
}
