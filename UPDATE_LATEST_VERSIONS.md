# Updating to Latest codex and claude-code Versions

This configuration uses overlays to build the latest versions of codex (0.55.0) and claude-code (2.0.34+).

## Current Status

The overlays are configured in `overlays.nix` with `lib.fakeHash` placeholders. These need to be replaced with correct hashes during the first build.

## How to Update the Hashes

### Method 1: During System Rebuild (Recommended)

1. Run `sudo nixos-rebuild switch --flake .`
2. The build will fail with hash mismatch errors
3. Look for lines like:
   ```
   specified: sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=
   got:       sha256-<ACTUAL_HASH_HERE>
   ```
4. Copy the "got" hash and update it in `overlays.nix`
5. Run `sudo nixos-rebuild switch --flake .` again
6. Repeat for any remaining hash mismatches

### Method 2: Test Build Individual Packages

Build each package separately to get its hash:

```bash
# For codex:
nix-build --no-out-link -E 'with import <nixpkgs> { overlays = [ (import /etc/nixos/overlays.nix { }).nixpkgs.overlays.0 ]; }; codex' 2>&1 | grep "got:"

# For claude-code:
nix-build --no-out-link -E 'with import <nixpkgs> { overlays = [ (import /etc/nixos/overlays.nix { }).nixpkgs.overlays.1 ]; }; claude-code' 2>&1 | grep "got:"
```

## Package Versions

- **codex**: 0.55.0 (from rust-v0.55.0 tag)
- **claude-code**: 2.0.34-unstable (from main branch HEAD: b95fa46)
- **beads**: 0.9.9 (from flake, already working)
- **vscode-fhs**: Latest from nixpkgs (already working)

## Fallback: Use nixpkgs Versions

If you prefer not to deal with hash updates, you can:

1. Remove `overlays.nix`
2. Remove overlay imports from `flake.nix`
3. Add `codex` and `claude-code` directly to `modules/home/packages.nix`

This will use slightly older but stable versions from nixpkgs (codex 0.50.0, claude-code 2.0.28).
