One-liner: Avoided Swift/.NET builds on macOS by moving `lldb`/`marksman`/`pre-commit` to Linux-only and installing macOS replacements via Homebrew, plus OS-specific flake checks.
Version: 1.0

Files Created
- .prompts/003-nix-macos-build-do/SUMMARY.md

Decisions Needed
- Confirm whether to keep Homebrew `llvm`/`swift` or rely on Xcode/CLT for Swift tooling.

Blockers
- None; darwin-rebuild should proceed once Homebrew installs complete.

Next Step
- Run `nix run github:LnL7/nix-darwin#darwin-rebuild -- switch --flake /Users/jwilger/nixos-config#sansa` and `brew bundle --global`.
