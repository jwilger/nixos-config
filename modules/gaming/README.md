# Steam Multi-Seat Gaming Module

This module provides a headless Steam gaming session that runs concurrently with your COSMIC desktop, enabling game streaming to SteamLink/AppleTV while you continue working.

## Architecture

- **Dedicated steam user**: System user (uid 987) with locked account
- **Systemd service**: `steam-gaming.service` runs gamescope + Steam automatically
- **Headless rendering**: Uses GPU render nodes, no DRM master conflict with COSMIC
- **Independent audio**: PipeWire automatically routes audio per session
- **Game library**: `/home/steam-library` (existing library preserved)

## Initial Setup: SteamLink PIN Pairing

The first time you connect from SteamLink/AppleTV, Steam will require PIN pairing. Since the gaming session runs headless (no visual output), use this procedure:

### Pairing Steps

1. **Stop the gaming service:**
   ```bash
   sudo systemctl stop steam-gaming.service
   ```

2. **Launch Steam as the steam user in your desktop session:**
   ```bash
   sudo -u steam DISPLAY=$DISPLAY steam
   ```

3. **Complete the pairing:**
   - Start SteamLink on your AppleTV
   - Enter the PIN shown on your AppleTV into the Steam interface
   - Verify connection succeeds

4. **Quit Steam** (close the window)

5. **Restart the gaming service:**
   ```bash
   sudo systemctl start steam-gaming.service
   ```

The pairing persists indefinitely. You only need to do this once (unless you unpair the device or reinstall Steam).

## Operation

### Service Management

```bash
# Check gaming service status
systemctl status steam-gaming.service

# View logs
journalctl -u steam-gaming.service -f

# Restart service
sudo systemctl restart steam-gaming.service

# Stop service temporarily
sudo systemctl stop steam-gaming.service
```

### Streaming from SteamLink

Once paired:
1. Open SteamLink app on AppleTV
2. Select your computer from the list
3. Games will stream at 4K@60Hz

Both your COSMIC desktop and the gaming session run simultaneously with independent audio streams.

## Configuration

The gaming session is configured in `/etc/nixos/modules/gaming/steam.nix`:

- **Resolution**: 3840x2160 @ 60Hz (modify `GAMESCOPE_WIDTH`, `GAMESCOPE_HEIGHT`, `GAMESCOPE_REFRESH`)
- **Performance overlay**: MangoHUD enabled (fps, frametime, temperatures)
- **GameMode**: Automatic CPU governor optimization

## Firewall

Steam Remote Play ports are automatically opened:
- TCP: 27036, 27037
- UDP: 27031, 27036

## Security

- **steam user**: Locked account, no password login
- **Power management**: steam user explicitly denied shutdown/reboot permissions
- **Service isolation**: NoNewPrivileges, PrivateTmp enabled

## Troubleshooting

### Service won't start

```bash
# Check detailed logs
journalctl -u steam-gaming.service -n 50

# Verify XDG_RUNTIME_DIR exists
ls -la /run/user/987
```

### SteamLink can't find computer

1. Verify service is running: `systemctl status steam-gaming.service`
2. Check firewall allows Remote Play ports
3. Ensure both devices on same network

### Audio routing issues

PipeWire handles per-session audio automatically. If issues occur:
```bash
# Check PipeWire status for steam user
sudo -u steam XDG_RUNTIME_DIR=/run/user/987 pw-cli ls
```

## Files

- `/etc/nixos/modules/gaming/steam.nix` - Main configuration
- `/etc/steam-gamescope-session` - Launch script
- `/home/steam-library/.local/share/Steam/` - Steam installation
- `/run/user/987/` - Steam user runtime directory
