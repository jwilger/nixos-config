<h1 align="center">
   <img src="./.github/assets/logo/nixos-logo.png  " width="100px" /> 
   <br>
      jwilger's Flakes 
   <br>
      <img src="https://raw.githubusercontent.com/catppuccin/catppuccin/main/assets/palette/macchiato.png" width="600px" /> <br>
   <div align="center">

   <div align="center">
      <p></p>
      <div align="center">
         <a href="https://github.com/Frost-Phoenix/nixos-config/stargazers">
            <img src="https://img.shields.io/github/stars/Frost-Phoenix/nixos-config?color=F5BDE6&labelColor=303446&style=for-the-badge&logo=starship&logoColor=F5BDE6">
         </a>
         <a href="https://github.com/Frost-Phoenix/nixos-config/">
            <img src="https://img.shields.io/github/repo-size/Frost-Phoenix/nixos-config?color=C6A0F6&labelColor=303446&style=for-the-badge&logo=github&logoColor=C6A0F6">
         </a>
         <a = href="https://nixos.org">
            <img src="https://img.shields.io/badge/NixOS-unstable-blue.svg?style=for-the-badge&labelColor=303446&logo=NixOS&logoColor=white&color=91D7E3">
         </a>
         <a href="https://github.com/Frost-Phoenix/nixos-config/blob/main/LICENSE">
            <img src="https://img.shields.io/static/v1.svg?style=for-the-badge&label=License&message=MIT&colorA=313244&colorB=F5A97F&logo=unlicense&logoColor=F5A97F&"/>
         </a>
      </div>
      <br>
   </div>
</h1>

<br>
</div>

### 🖼️ Gallery

<p align="center">
   <img src="./.github/assets/screenshots/1.png" /> <br>
   <img src="./.github/assets/screenshots/2.png" /> <br>
   <img src="./.github/assets/screenshots/3.png" /> <br>
   Screenshots last updated <b>2024-04-09</b>
</p>

<details>
<summary>
OLD (EXPAND)
</summary>
<p align="center">
   <img src="./.github/assets/screenshots/1.old.png" width="800px" /> <br>
   <img src="./.github/assets/screenshots/2.old.png" width="800px" /> <br>
   <img src="./.github/assets/screenshots/3.old.png" width="800px" /> <br>
</p>
</details>

# 🗃️ Overview

### 📚 Layout

-   [flake.nix](flake.nix) - Entry point of the configuration
-   [hosts](hosts) - 🌳 Per-host configurations:
    - [desktop](hosts/desktop/) - 🖥️ Desktop configuration with bcachefs, amdgpu, and Intel CPU support
    - [laptop](hosts/laptop/) - 💻 Laptop configuration with ext4 and Intel CPU support
    - [vm](hosts/vm/) - 🖥️ VM configuration with QEMU guest profile and virtio support
-   [modules](modules) - 🔧 Configuration modules:
    - [core](modules/core/) - ⚙️ System-level configurations:
        - Hardware, networking, security, services, system settings
        - Bootloader, pipewire, virtualization, wayland/xserver
    - [home](modules/home/) - 🏠 User environment configurations:
        - Desktop applications (VSCodium, Floorp, Discord, etc.)
        - Shell environment (Zsh, Starship)
        - Window manager (Hyprland) and desktop components
        - Development tools and utilities
        - Custom scripts and theming

### 📓 Components
|                             | NixOS + Hyprland                                                                              |
| --------------------------- | :---------------------------------------------------------------------------------------------:
| **Window Manager**          | [Hyprland][Hyprland] |
| **Bar**                     | [Waybar][Waybar] |
| **Application Launcher**    | [fuzzel][fuzzel] |
| **Notification Daemon**     | [swaync][swaync] |
| **Terminal Emulator**       | [Kitty][Kitty] |
| **Shell**                   | [zsh][zsh] + [oh-my-zsh][oh-my-zsh] + [Starship][Starship] |
| **Text Editor**             | [VSCodium][VSCodium] + [Neovim][Neovim] |
| **network management tool** | [NetworkManager][NetworkManager] + [network-manager-applet][network-manager-applet] |
| **System resource monitor** | [Btop][Btop] |
| **File Manager**            | [nemo][nemo] + [yazi][yazi] |
| **Fonts**                   | [Nerd fonts][Nerd fonts] |
| **Color Scheme**            | [Catppuccin][Catppuccin] |
| **Cursor**                  | [Nordzy-cursors][Nordzy-cursors] |
| **Icons**                   | [catppuccin-papirus-folders][catppuccin-papirus-folders] |
| **Lockscreen**              | [Swaylock-effects][Swaylock-effects] |
| **Image Viewer**            | [imv][imv] |
| **Media Player**            | [mpv][mpv] |
| **Music Player**            | [audacious][audacious] |
| **Screenshot Software**     | [grimblast][grimblast] |
| **Screen Recording**        | [wf-recorder][wf-recorder] |
| **Clipboard**               | [wl-clip-persist][wl-clip-persist] |
| **Color Picker**            | [hyprpicker][hyprpicker] |


### 📝 Shell aliases

<details>
<summary>
Utils (EXPAND)
</summary>

- ```c```     $\rightarrow$ ```clear```
- ```cd```    $\rightarrow$ ```z```
- ```tt```    $\rightarrow$ ```gtrash put```
- ```vim```   $\rightarrow$ ```nvim```
- ```cat```   $\rightarrow$ ```bat```
- ```nano```  $\rightarrow$ ```micro```
- ```icat```  $\rightarrow$ ```kitten icat```
- ```dsize``` $\rightarrow$ ```du -hs```
- ```findw``` $\rightarrow$ ```grep -rl```
- ```l```     $\rightarrow$ ```eza --icons  -a --group-directories-first -1```
- ```ll```    $\rightarrow$ ```eza --icons  -a --group-directories-first -1 --no-user --long```
- ```tree```  $\rightarrow$ ```eza --icons --tree --group-directories-first```
</details>

<details>
<summary>
Nixos (EXPAND)
</summary>

> ${host} is either `desktop` or `laptop`

- ```cdnix```            $\rightarrow$ ```cd ~/nixos-config && codium ~/nixos-config```
- ```ns```               $\rightarrow$ ```nix-shell --run zsh```
- ```nix-switch```       $\rightarrow$ ```sudo nixos-rebuild switch --flake ~/nixos-config#${host}```
- ```nix-switchu```      $\rightarrow$ ```sudo nixos-rebuild switch --upgrade --flake ~/nixos-config#${host}```
- ```nix-flake-update``` $\rightarrow$ ```sudo nix flake update ~/nixos-config#```
- ```nix-clean```        $\rightarrow$ ```sudo nix-collect-garbage && sudo nix-collect-garbage -d && sudo rm /nix/var/nix/gcroots/auto/* && nix-collect-garbage && nix-collect-garbage -d```
</details>

<details>
<summary>
Git (EXPAND)
</summary>

- ```ga```   $\rightarrow$ ```git add```
- ```gaa```  $\rightarrow$ ```git add --all```
- ```gs```   $\rightarrow$ ```git status```
- ```gb```   $\rightarrow$ ```git branch```
- ```gm```   $\rightarrow$ ```git merge```
- ```gpl```  $\rightarrow$ ```git pull```
- ```gplo``` $\rightarrow$ ```git pull origin```
- ```gps```  $\rightarrow$ ```git push```
- ```gpso``` $\rightarrow$ ```git push origin```
- ```gc```   $\rightarrow$ ```git commit```
- ```gcm```  $\rightarrow$ ```git commit -m```
- ```gch```  $\rightarrow$ ```git checkout```
- ```gchb``` $\rightarrow$ ```git checkout -b```
- ```gcoe``` $\rightarrow$ ```git config user.email```
- ```gcon``` $\rightarrow$ ```git config user.name```
</details>

### 🛠️ Scripts

All the scripts are in ```modules/home/scripts/scripts/``` and are exported as packages in ```modules/home/scripts/default.nix```

<details>
<summary>
extract.sh 
</summary>

**Description:** This script extract ```tar.gz``` archives in the current directory.

**Usage:** ```extract <archive_file>```
</details>

<details>
<summary>
compress.sh 
</summary>

**Description:** This script compress a file or a folder into a ```tar.gz``` archives which is created in the current directory with the name of the chosen file or folder. 

**Usage:** ```compress <file>``` or ```compress <folder>```
</details>

<details>
<summary>
toggle_blur.sh 
</summary>

**Description:** This script toggles the Hyprland blur effect. If the blur is currently enabled, it will be disabled, and if it's disabled, it will be turned on. 

**Usage:** ```toggle_blur```
</details>

<details>
<summary>
toggle_oppacity.sh 
</summary>

**Description:** This script toggles the Hyperland oppacity effect. If the oppacity is currently set to 0.90, it will be set to 1, and if it's set to 1, it will be set to 0.90. 

**Usage:** ```toggle_oppacity```
</details>

<details>
<summary>
maxfetch.sh 
</summary>

**Description:** This script is a modified version of the [jobcmax/maxfetch][maxfetch] script.

**Usage:** ```maxfetch```
</details>

<details>
<summary>
music.sh 
</summary>

**Description:** This script is for managing Audacious (music player). If Audacious is currently running, it will be killed (stopping the music); otherwise, it will start Audacious in the 8th workspace and resume the music. 

**Usage:** ```music```
</details>

<details>
<summary>
runbg.sh 
</summary>

**Description:** This script runs a provided command along with its arguments and detaches it from the terminal. Handy for launching apps from the command line without blocking it. 

**Usage:** ```runbg <command> <arg1> <arg2> <...>```
</details>

### ⌨️ Keybinds

View all keybinds by pressing ```$mainMod F1```. By default ```$mainMod``` is the ```SUPER``` key. 

<details>
<summary>
Basic Controls
</summary>

- ```$mainMod, Return``` → ```kitty```
- ```ALT, Return``` → ```kitty --title float_kitty```
- ```$mainMod SHIFT, Return``` → ```kitty --start-as=fullscreen -o 'font_size=16'```
- ```$mainMod, B``` → ```floorp``` (workspace 1)
- ```$mainMod, Q``` → Kill active window
- ```$mainMod, F``` → Toggle fullscreen
- ```$mainMod SHIFT, F``` → Toggle true fullscreen
- ```$mainMod, D``` → Toggle floating
- ```$mainMod, SPACE``` → Launch fuzzel
- ```$mainMod SHIFT, D``` → Launch Discord (workspace 4)
- ```$mainMod SHIFT, S``` → Launch SoundWireServer (workspace 5)
- ```$mainMod, Escape``` → Lock screen
- ```$mainMod SHIFT, Escape``` → Shutdown menu
- ```$mainMod, P``` → Toggle pseudo mode
- ```$mainMod, X``` → Toggle split
- ```$mainMod, E``` → Launch file manager
- ```$mainMod SHIFT, B``` → Reload Waybar
- ```$mainMod, C``` → Color picker
- ```$mainMod, W``` → Wallpaper picker
- ```$mainMod SHIFT, W``` → Start VM
</details>

<details>
<summary>
Screenshot
</summary>

- ```$mainMod, Print``` → Save area screenshot
- ```Print``` → Copy area screenshot
</details>

<details>
<summary>
Focus Control
</summary>

- ```$mainMod, h``` → Focus left
- ```$mainMod, l``` → Focus right
- ```$mainMod, k``` → Focus up
- ```$mainMod, j``` → Focus down
</details>

<details>
<summary>
Window Control
</summary>

- ```$mainMod SHIFT, h``` → Move window left
- ```$mainMod SHIFT, l``` → Move window right
- ```$mainMod SHIFT, k``` → Move window up
- ```$mainMod SHIFT, j``` → Move window down
- ```$mainMod CTRL, h``` → Resize window left
- ```$mainMod CTRL, l``` → Resize window right
- ```$mainMod CTRL, k``` → Resize window up
- ```$mainMod CTRL, j``` → Resize window down
- ```$mainMod ALT, h``` → Move window left (fine)
- ```$mainMod ALT, l``` → Move window right (fine)
- ```$mainMod ALT, k``` → Move window up (fine)
- ```$mainMod ALT, j``` → Move window down (fine)
</details>

<details>
<summary>
Workspace Control
</summary>

- ```$mainMod, 1-0``` → Switch to workspace 1-10
- ```$mainMod SHIFT, 1-0``` → Move window to workspace 1-10
- ```$mainMod CTRL, c``` → Move window to empty workspace
</details>

<details>
<summary>
Media and Volume Controls
</summary>

- ```XF86AudioRaiseVolume``` → Volume up
- ```XF86AudioLowerVolume``` → Volume down
- ```XF86AudioMute``` → Toggle mute
- ```XF86AudioPlay``` → Play/pause
- ```XF86AudioNext``` → Next track
- ```XF86AudioPrev``` → Previous track
- ```XF86AudioStop``` → Stop playback
- ```$mainMod, mouse_down``` → Previous workspace
- ```$mainMod, mouse_up``` → Next workspace
</details>

<details>
<summary>
Brightness Control
</summary>

- ```XF86MonBrightnessUp``` → Brightness up (5%)
- ```XF86MonBrightnessDown``` → Brightness down (5%)
- ```$mainMod XF86MonBrightnessUp``` → Brightness up (100%)
- ```$mainMod XF86MonBrightnessDown``` → Brightness down (100%)
</details>

<details>
<summary>
Clipboard
</summary>

- ```$mainMod, V``` → Open clipboard manager
</details>

<details>
<summary>
Mouse Bindings
</summary>

- ```$mainMod + Left Mouse``` → Move window
- ```$mainMod + Right Mouse``` → Resize window
</details>

# 🚀 Installation 

> **⚠️ Use this configuration at your own risk! ⚠️** <br>
> Applying custom configurations, especially those related to your operating system, can have unexpected consequences and may interfere with your system's normal behavior. While I have tested these configurations on my own setup, there is no guarantee that they will work flawlessly on all systems. <br>
> **I am not responsible for any issues that may arise from using this configuration.**

> It is highly recommended to review the configuration contents and make necessary modifications to customize it to your needs before attempting the installation.

### 🚀 Installation 

> **⚠️ Important Filesystem Note ⚠️** <br>
> This configuration supports both bcachefs (desktop) and ext4 (laptop) installations. Make sure to choose the appropriate host configuration based on your filesystem choice during NixOS installation.

> **⚠️ Use this configuration at your own risk! ⚠️** <br>

2. **Clone the repo**

   ```
   nix-shell -p git
   git clone https://github.com/Frost-Phoenix/nixos-config
   cd nixos-config
   ```
3. **Install script**

   > First make sure to read the install script, it isn't long
   
   Execute and follow the installation script :
   ```
   ./install.sh
   ```
   > You will need to change the git account yourself in ./modules/home/git.nix
   ```
      programs.git = {
         ...
         userName = "Frost-Phoenix";
         userEmail = "67cyril6767@gmail.com";
         ...
      };
   ```
4. **Reboot**

   After rebooting, you'll be greeted by swaylock prompting for your password, with the wallpaper in the background.

5. **Manual config**

   Even though I use home manager, there is still a little bit of manual configuration to do:
      - Set Aseprite theme (they are in the folder `./nixos-config/modules/home/aseprite/themes`).
      - Enable Discord theme (in Discord settings under VENCORD > Themes).
      - Configure the browser (for now, all browser configuration is done manually).

### Install script walkthrough

A brief walkthrough of what the install script does.

1. **Get username**

   You will receive a prompt to enter your username, with a confirmation check.

2. **Set username**

   The script will replace all occurancies of the default usename ```CURRENT_USERNAME``` by the given one stored in ```$username```

3. Create basic directories

   The following directories will be created:
   - ```~/Music```
   - ```~/Documents```
   - ```~/Pictures/wallpapers/others```

4. Copy the wallpapers

   Then the wallpapers will be copied into ```~/Pictures/wallpapers/others``` which is the folder in which the ```wallpaper-picker.sh``` script will be looking for them.

5. Get the hardware configuration

   It will also automatically copy the hardware configuration from ```/etc/nixos/hardware-configuration.nix``` to ```./hosts/nixos/hardware-configuration.nix``` so that the hardware configuration used is yours and not the default one.

6. Choose a host (desktop / laptop)

   Now you will need to choose the host you want. It depend on whether you are using a desktop or laptop.

7. Build the system

   Lastly, it will build the system, which includes both the flake config and home-manager config.

# 👥 Credits

Other dotfiles that I learned / copy from:

- Nix Flakes
  - [nomadics9/NixOS-Flake](https://github.com/nomadics9/NixOS-Flake): This is where I start my nixos / hyprland journey.
  - [samiulbasirfahim/Flakes](https://github.com/samiulbasirfahim/Flakes): General flake / files structure
  - [justinlime/dotfiles](https://github.com/justinlime/dotfiles): Mainly waybar (old design)
  - [skiletro/nixfiles](https://github.com/skiletro/nixfiles): Vscodium config (that prevent it to crash)
  - [fufexan/dotfiles](https://github.com/fufexan/dotfiles)

- README
  - [ryan4yin/nix-config](https://github.com/ryan4yin/nix-config)
  - [NotAShelf/nyx](https://github.com/NotAShelf/nyx)
  - [sioodmy/dotfiles](https://github.com/sioodmy/dotfiles)
  - [Ruixi-rebirth/flakes](https://github.com/Ruixi-rebirth/flakes)


<!-- # ✨ Stars History -->

<!-- <p align="center"><img src="https://api.star-history.com/svg?repos=frost-phoenix/nixos-config&type=Timeline&theme=dark" /></p> -->

<p align="center"><img src="https://raw.githubusercontent.com/catppuccin/catppuccin/main/assets/footers/gray0_ctp_on_line.svg?sanitize=true" /></p>

<!-- end of page, send back to the top -->

<div align="right">
  <a href="#readme">Back to the Top</a>
</div>

<!-- Links -->
<!-- Links -->
[...verify all links are still valid and point to correct resources...]
