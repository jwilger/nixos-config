# Repository Guidelines

## Project Structure & Module Organization
- The root `flake.nix` defines inputs and exports the Gregor configuration; treat it as the authoritative entry point.
- Gregor's host profile lives under `hosts/gregor` and composes hardware configuration with shared system modules.
- Shared system modules belong in `modules/core` or `modules/desktop`; user configuration lives in the pinned `jwilger/home` flake.
- Assets for docs and screenshots are stored in `.github/assets`; keep generated artifacts out of version control.

## Build, Test, and Development Commands
- `nix flake update` refreshes inputs; run before large upgrades to sync `flake.lock`.
- `nix flake check` validates all configurations and catches evaluation errors; run before commits.
- `nixos-rebuild dry-run --flake .#gregor` validates the host build without applying changes.
- `nixos-rebuild switch --flake .#gregor` builds and activates the target system.
- `home-manager switch --flake github:jwilger/home#jwilger@gregor` applies the published user profile directly.
- `nix build .#checks.x86_64-linux.gregor-home` validates the pinned Home Manager profile without activation.

## Coding Style & Naming Conventions
- Format Nix files with `nixpkgs-fmt` (2-space indent, trailing commas on multi-line attribute sets, alphabetical option ordering).
- Function parameters: multi-line with one param per line (`{ pkgs, config, lib, ... }:`), alphabetized when practical.
- Use `let...in` blocks for complex derivations; prefer `lib.getExe` or `lib.getExe'` over hardcoded paths.
- String interpolation: `"${pkgs.foo}/bin/bar"` for paths, `${config.home.homeDirectory}` for dynamic values.
- Name host directories with lowercase hostnames and keep module filenames as `default.nix`.
- Keep option names descriptive and match upstream NixOS option casing; prefer inline comments sparingly to justify deviations.

## Testing Guidelines
- `nix flake check` should pass before publishing; it catches evaluation and formatting regressions.
- Use `nixos-rebuild dry-run` for smoke tests and capture the summary in PRs when changes touch core modules.
- Validate Home Manager updates with `nix build .#checks.x86_64-linux.gregor-home` to avoid surprises.

## Commit & Pull Request Guidelines
- Follow the existing short, imperative commit style (`chore: cleanup`, `Update cosmic desktop theme`) and keep scope narrow; group lockfile bumps separately.
- Reference related issues in the body when available and note host(s) impacted in the PR description.
- Include command outputs (`nix flake check`, `nixos-rebuild dry-run`) in PR discussions, plus screenshots when UI or theme assets in `.github/assets` change.

## Security & Configuration Tips
- Never commit secrets or unencrypted private keys; prefer NixOS `sops` or environment variables stored outside the repo.
- Review firewall and network changes in `hosts/<hostname>` carefully to maintain parity across hosts.
