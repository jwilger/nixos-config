{
config,
lib,
pkgs,
...
}: {
  nixpkgs.config.allowUnfree = true;

  news.display = "silent";

  xdg.portal.config.common.default = "*";

  stylix = {
    enable = true;
    image = ./wallpaper.png;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-macchiato.yaml";
    polarity = "dark";
    targets = {
      hyprlock.enable = false;
      neovim.enable = false;
    };
  };

  wayland.windowManager.hyprland = {
    enable = true;
    package = null;
    portalPackage = null;
    systemd = {
      enable = true;
      enableXdgAutostart = true;
    };
    settings = {
      exec-once = [
        "dbus-update-activation-environment --systemd --all WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
        "systemctl --user import-environment QT_QPA_PLATFORMTHEME WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
        "${pkgs._1password-gui}/bin/1password --silent"
        "${pkgs.solaar}/bin/solaar -w hide"
      ];
      monitor = ",preferred,auto,auto";
      "$terminal" = "kitty";
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
      env = NIXPKGS_ALLOW_UNFREE, 1
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
      $terminal = ${pkgs.kitty}/bin/kitty
      $menu = ${pkgs.fuzzel}/bin/fuzzel
      $logout = ${pkgs.wlogout}/bin/wlogout
      $browser = ${pkgs.firefox}/bin/firefox
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

  home = {
    # Don't change this. Ever.
    stateVersion = "24.11"; # Please read the comment before changing.

    # Home Manager needs a bit of information about you and the paths it should
    # manage.
    username = "jwilger";
    homeDirectory = "/home/jwilger";

    sessionVariables = {
      NIX_BUILD_SHELL = "zsh";
      PATH = "$HOME/.local/bin:$PATH";
    };

    # The home.packages option allows you to install Nix packages into your
    # environment.
    packages = with pkgs; [
      _1password-gui
      _1password-cli
      docker-client
      dwt1-shell-color-scripts
      fd
      firefoxpwa
      fzf
      gcc
      gh
      grim
      kitty
      libnotify
      nautilus
      nil
      powerline
      ripgrep
      slack
      slurp
      solaar
      swaynotificationcenter
      wl-clipboard
      zellij
    ];

    pointerCursor = {
      enable = true;
      gtk.enable = true;
      dotIcons.enable = true;
      hyprcursor.enable = true;
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Classic";
      size = 16;
    };
  };

  gtk = {
    enable = true;

    iconTheme = {
      package = pkgs.adwaita-icon-theme;
      name = "Adwaita";
    };
  };

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

  programs = {
    sioyek.enable = true;
    obs-studio.enable = true;

    firefox = {
      enable = true;
      package = pkgs.firefox;
      nativeMessagingHosts = [pkgs._1password-gui];
    };

    waybar = {
      enable = true;
      systemd.enable = true;
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
          path = "${./wallpaper.png}";
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
            path = "${./profile-picture.jpg}";
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

    htop.enable = true;

    neovim = {
      defaultEditor = true;
      enable = true;
      viAlias = true;
      vimAlias = true;
      vimdiffAlias = true;
      withNodeJs = true;
      withPython3 = true;
      withRuby = true;
    };

    lazygit = {
      enable = true;
      settings = {
        gui = {
          expandFocusedSidePanel = true;
          showRandomTip = false;
          nerdFontsVersion = "3";
        };
      };
    };
    git = {
      enable = true;
      userName = "John Wilger";
      userEmail = "john@johnwilger.com";

      ignores = [
        # ignore direv files
        ".envrc"
        ".direnv/"
      ];
      difftastic = {
        enable = true;
      };

      signing = {
        format = "ssh";
        key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGwXlUIgMZDNewfvIyX5Gd1B1dIuLT7lH6N+2+FrSaSU";
        signByDefault = true;
        signer = "op-ssh-sign";
      };

      extraConfig = {
        init.defaultBranch = "main";
        merge.conflictstyle = "zdiff3";
        merge.tool = "nvimdiff";
        diff.tool = "nvimdiff";
        log.showSignature = true;
        gpg = {
          ssh.allowedSignersFile = "${config.home.homeDirectory}/${config.xdg.configFile."ssh/allowed_signers".target}";
        };
        pull = {
          ff = "only";
        };
        push = {
          default = "current";
        };
        safe.directory = "/etc/nixos";
      };
    };

    gpg = {
      enable = true;
      mutableKeys = true;
      mutableTrust = true;
      publicKeys = [
        {
          source = builtins.fetchurl {
            url = "https://github.com/web-flow.gpg";
            sha256 = "117gldk49gc76y7wqq6a4kjgkrlmdsrb33qw2l1z9wqcys3zd2kf";
          };
          trust = 4;
        }
      ];
    };

    direnv = {
      enable = true;
      enableZshIntegration = true;
      nix-direnv.enable = true;
    };
    ssh = {
      enable = true;
      compression = true;
      forwardAgent = true;
      controlMaster = "yes";
      matchBlocks = {
        "hydrogen.slipstreamconsulting.net" = {
          user = "admin";
        };
      };
    };
    starship = {
      enable = true;
      enableZshIntegration = true;
      settings = {
        format = "[╭╴](fg:#505050)$os$username$hostname$sudo$directory$git_branch$git_commit$git_state$git_metrics$git_status$jobs$memory_usage[ ](fg:#242424)$cmd_duration$fill$line_break[╰╴](fg:#505050)[$status $localip $character]($style)";
        add_newline = true;
        os = {
          format = "[$symbol ]($style)[ ]()";
          style = "fg:#AAAAAA";
          disabled = false;
          symbols = {
            Alpine = "";
            Amazon = "";
            Android = "";
            Arch = "";
            CentOS = "";
            Debian = "";
            DragonFly = "🐉";
            Emscripten = "🔗";
            EndeavourOS = "";
            Fedora = "";
            FreeBSD = "";
            Garuda = "";
            Gentoo = "";
            HardenedBSD = "聯";
            Illumos = "🐦";
            Linux = "";
            Macos = "";
            Manjaro = "";
            Mariner = "";
            MidnightBSD = "🌘";
            Mint = "";
            NetBSD = "";
            NixOS = "";
            OpenBSD = "";
            OpenCloudOS = "☁️";
            openEuler = "";
            openSUSE = "";
            OracleLinux = "⊂⊃";
            Pop = "";
            Raspbian = "";
            Redhat = "";
            RedHatEnterprise = "";
            Redox = "🧪";
            Solus = "";
            SUSE = "";
            Ubuntu = "";
            Unknown = "";
            Windows = "";
          };
        };
        username = {
          format = "[ ](fg:green bold)[$user]($style)[ ]()";
          style_user = "fg:green bold";
          style_root = "fg:red bold";
          show_always = false;
          disabled = false;
        };
        hostname = {
          format = "[$ssh_symbol ](fg:green bold)[$hostname](fg:green bold)[ ]()";
          ssh_only = true;
          ssh_symbol = "";
          disabled = false;
        };
        directory = {
          format = "[ ](fg:cyan bold)[$read_only]($read_only_style)[$repo_root]($repo_root_style)[$path]($style)";
          style = "fg:cyan bold";
          home_symbol = " ~";
          read_only = " ";
          read_only_style = "fg:cyan";
          truncation_length = 3;
          truncation_symbol = "…/";
          truncate_to_repo = true;
          repo_root_format = "[ ](fg:cyan bold)[$read_only]($read_only_style)[$before_root_path]($before_repo_root_style)[$repo_root]($repo_root_style)[$path]($style)[ ]()";
          repo_root_style = "fg:cyan bold";
          use_os_path_sep = true;
          disabled = false;
        };
        git_branch = {
          format = "[❯ $symbol $branch(:$remote_branch)]($style)[ ]()";
          style = "fg:#E04D27";
        };
        git_commit = {
          format = "[\($hash$tag\)]($style)[ ]()";
          style = "fg:#E04D27";
          commit_hash_length = 8;
          tag_symbol = " ";
          disabled = false;
        };
        git_metrics = {
          format = "[[+\${added}/](\${added_style})[-\${deleted}](\${deleted_style})[  ]()]()";
          added_style = "fg:#E04D27";
          deleted_style = "fg:#E04D27";
          disabled = false;
          only_nonzero_diffs = true;
        };
        git_status = {
          format = "([$all_status$ahead_behind]($style))";
          style = "fg:#E04D27";
          conflicted = "[  \${count} ](fg:red)";
          ahead = "[ ⇡ \${count} ](fg:yellow)";
          behind = "[ ⇣ \${count} ](fg:yellow)";
          diverged = "[ ⇕ \${ahead_count}⇡ \${behind_count}⇣ ](fg:yellow)";
          up_to_date = "[ ✓ ](fg:green)";
          untracked = "[ ﳇ \${count} ](fg:red)";
          stashed = "[  \${count} ](fg:#A52A2A)";
          modified = "[  \${count} ](fg:#C8AC00)";
          staged = "[  \${count} ](fg:green)";
          renamed = "[ ᴂ \${count} ](fg:yellow)";
          deleted = "[ 🗑 \${count} ](fg:orange)";
          disabled = false;
        };
        jobs = {
          format = "[  ](fg:blue bold)[$number$symbol]($style)";
          style = "fg:blue";
          symbol = "省";
          symbol_threshold = 1;
          number_threshold = 4;
          disabled = false;
        };
        memory_usage = {
          format = "[  ](fg:purple bold)[$symbol \${ram} \${swap}]($style)";
          style = "fg:purple";
          symbol = "﬙ 北";
          threshold = 75;
          disabled = false;
        };
        cmd_duration = {
          format = "[  $duration ]($style)";
          style = "fg:yellow";
          min_time = 500;
          disabled = false;
        };
        fill = {
          style = "fg:#505050";
          symbol = "─";
        };
        status = {
          format = "[$symbol$status $hex_status  $signal_number-$signal_name ]($style)";
          style = "fg:red";
          symbol = "✘ ";
          disabled = false;
        };
        localip = {
          format = "[$localipv4 ](fg:green bold)";
          ssh_only = true;
          disabled = true;
        };
      };
    };
    zsh = {
      enable = true;
      enableCompletion = true;
      history = {
        ignoreDups = true;
        share = true;
      };
      oh-my-zsh = {
        enable = true;
        plugins = [
          "git"
          "sudo"
          "keychain"
          "direnv"
          "mix"
          "pyenv"
          "gpg-agent"
        ];
      };
      plugins = [
        {
          name = "zsh-nix-shell";
          file = "nix-shell.plugin.zsh";
          src = pkgs.fetchFromGitHub {
            owner = "chisui";
            repo = "zsh-nix-shell";
            rev = "v0.8.0";
            sha256 = "1lzrn0n4fxfcgg65v0qhnj7wnybybqzs4adz7xsrkgmcsr0ii8b7";
          };
        }
      ];
      shellAliases = {
        # Git
        gst = "git status";
        gci = "git commit";
        gap = "git add --patch";

        # OS
        ls = "ls -lGh";
        envs = "env | sort";
        envg = "env | grep -i";

        # Random
        guid = ''uuidgen | tr "[:upper:]" "[:lower:]"'';
        publicip = "dig +short myip.opendns.com @resolver1.opendns.com";
        localip = ''ifconfig | grep "inet " | grep -v 127.0.0.1 | cut -d\  -f2'';

        # zellij
        zz = ''
           zellij --layout=.zellij.kdl attach -c "`basename \"$PWD\"`"
        '';

        za = ''
           zellij attach --index 0
        '';

        # GitHub CLI
        ghr = "gh run watch";

        # NixOS and Home Manager Stuff
        full-rebuild = "sudo nixos-rebuild switch && home-manager switch";
      };
      syntaxHighlighting = {
        enable = true;
      };

      envExtra = ''
         if [[ -z "$SSH_AUTH_SOCK" ]]; then
           export SSH_AUTH_SOCK="/home/jwilger/.1password/agent.sock"
         fi
      '';
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

  xdg = {
    configFile = {
      "ssh/allowed_signers".text = ''
        john@johnwilger.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGwXlUIgMZDNewfvIyX5Gd1B1dIuLT7lH6N+2+FrSaSU
        johnwilger@artium.ai ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGwXlUIgMZDNewfvIyX5Gd1B1dIuLT7lH6N+2+FrSaSU
      '';

      "zellij/config.kdl".text = with config.lib.stylix.colors.withHashtag; ''
        session_serialization false
        theme "stylix"
        themes {
          stylix {
            fg "${base03}"
            bg "${base05}"
            black "${base00}"
            red "${base08}"
            green "${base0B}"
            yellow "${base0A}"
            blue "${base0D}"
            magenta "${base0E}"
            cyan "${base0C}"
            white "${base07}"
            orange "${base09}"
          }
        }
        default_layout "compact"
        mouse_mode true
        mirror_session true
        pane_frames true
        ui {
          pane_frames {
            rounded_corners true
          }
        }
        keybinds {
          normal clear-defaults=true {
            bind "F12" { SwitchToMode "locked"; }
            bind "Ctrl a" { SwitchToMode "tmux"; }
          }
          locked clear-defaults=true {
            bind "F12" { SwitchToMode "Normal"; }
          }
          tmux {
            unbind "Ctrl b"
            bind "s" {
              LaunchOrFocusPlugin "session-manager" {
                floating true
                move_to_focused_tab true
              };
              SwitchToMode "Normal"
            }
            bind "[" { SwitchToMode "Scroll"; }
            bind "Ctrl a" { Write 1; SwitchToMode "Normal"; }
            bind "\\" { NewPane "Right"; SwitchToMode "Normal"; }
            bind "-" { NewPane "Down"; SwitchToMode "Normal"; }
            bind "z" { ToggleFocusFullscreen; SwitchToMode "Normal"; }
            bind "c" { NewTab; SwitchToMode "Normal"; }
            bind "," { SwitchToMode "RenameTab"; }
            bind "i" { ToggleTab; SwitchToMode "Normal"; }
            bind "p" { GoToPreviousTab; SwitchToMode "Normal"; }
            bind "n" { GoToNextTab; SwitchToMode "Normal"; }
            bind "h" { MoveFocus "Left"; SwitchToMode "Normal"; }
            bind "j" { MoveFocus "Down"; SwitchToMode "Normal"; }
            bind "k" { MoveFocus "Up"; SwitchToMode "Normal"; }
            bind "l" { MoveFocus "Right"; SwitchToMode "Normal"; }
            bind "d" { Detach; }
            bind "Space" { NextSwapLayout; SwitchToMode "Normal"; }
            bind "x" { CloseFocus; SwitchToMode "Normal"; }
            bind "f" { ToggleFloatingPanes; SwitchToMode "Normal"; }
            bind "1" { GoToTab 1; SwitchToMode "Normal"; }
            bind "2" { GoToTab 2; SwitchToMode "Normal"; }
            bind "3" { GoToTab 3; SwitchToMode "Normal"; }
            bind "4" { GoToTab 4; SwitchToMode "Normal"; }
            bind "5" { GoToTab 5; SwitchToMode "Normal"; }
            bind "6" { GoToTab 6; SwitchToMode "Normal"; }
            bind "7" { GoToTab 7; SwitchToMode "Normal"; }
            bind "8" { GoToTab 8; SwitchToMode "Normal"; }
            bind "9" { GoToTab 9; SwitchToMode "Normal"; }
            bind "e" { EditScrollback; SwitchToMode "Normal"; }
            bind "m" { SwitchToMode "move"; }
            bind "=" { SwitchToMode "resize"; }
            bind "q" { Quit; }
            bind "g" {
              Run "lazygit" {
                floating true
                close_on_exit true
              }
              SwitchToMode "Normal"
            }
          }
          shared_except "locked" {
            bind "F12" { SwitchToMode "Locked"; }
          }
        }
      '';

      "solaar/config.yaml".source = ./solaar_config.yaml;
      "solaar/rules.yaml".source = ./solaar_rules.yaml;
    };
  };
}
