# Steam Multi-Seat Gaming Module

This module provides a headless Steam gaming session that runs concurrently with your COSMIC desktop, enabling game streaming to Moonlight/AppleTV while you continue working.

## Architecture

- **Dedicated steam user**: System user (uid 987) with locked account
- **Systemd service**: `steam-gaming.service` runs gamescope + Steam automatically
- **Headless rendering**: Uses GPU render nodes, no DRM master conflict with COSMIC
- **Independent audio**: PipeWire automatically routes audio per session
- **Game library**: `/home/steam-library` (existing library preserved)

## Initial Setup: Sunshine Pairing

Sunshine streams games from the headless gamescope session. Initial pairing is done via web interface:

### Pairing Steps

1. **Access Sunshine web interface:**
   - Open browser to `https://gregor:47990`
   - Default credentials: `admin` / `admin` (change immediately!)

2. **Configure Sunshine:**
   - Set secure password
   - Configure video codec (H.264/HEVC - HEVC recommended for 4K)
   - Set bitrate (50 Mbps for 4K recommended)

3. **Pair Moonlight client:**
   - Install Moonlight app on AppleTV
   - Moonlight will auto-discover "gregor"
   - Enter PIN shown in Moonlight into Sunshine web interface
   - Pairing persists indefinitely

No need to restart services - Sunshine runs automatically with the gaming session.

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

### Streaming from Moonlight

Once paired:
1. Open Moonlight app on AppleTV
2. Select "gregor" from discovered hosts
3. Choose "Desktop" or specific game from list
4. Games stream at up to 4K@60Hz (adapts to network conditions)

Both your COSMIC desktop and the gaming session run simultaneously with independent audio streams.

## Configuration

The gaming session is configured in `/etc/nixos/modules/gaming/steam.nix`:

- **Resolution**: 3840x2160 @ 60Hz (modify `GAMESCOPE_WIDTH`, `GAMESCOPE_HEIGHT`, `GAMESCOPE_REFRESH`)
- **Performance overlay**: MangoHUD enabled (fps, frametime, temperatures)
- **GameMode**: Automatic CPU governor optimization

## Firewall

Sunshine streaming ports are automatically opened:
- TCP: 47984-47990 (HTTPS web UI, RTSP)
- UDP: 47998-48000 (Video/Audio streaming)

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

### Moonlight can't find host

1. Verify service is running: `systemctl status steam-gaming.service`
2. Verify Sunshine is running: `systemctl status sunshine`
3. Check firewall allows Sunshine ports (47984-48000)
4. Ensure both devices on same network
5. Try manual connection in Moonlight using IP address

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
