# SUMMARY

One-liner: Plan to make `sansa` nix-darwin builds succeed by removing Swift/.NET Nix builds and using Homebrew replacements.

Version: 1.0

Key Findings:
- `lldb` and `marksman` in `modules/home/packages.nix` trigger Swift and .NET builds on macOS.
- Guarding those packages on macOS preserves Linux parity while avoiding heavy macOS builds.
- Homebrew can supply `marksman`, `dotnet`, and the Swift toolchain on macOS.

Decisions Needed:
- Whether to install `llvm` via Homebrew for `lldb` or rely on Xcode/CLT.
- Whether to use the `swift` Homebrew cask for the Swift toolchain or rely on Xcode/CLT.

Blockers:
- None identified; plan is low-risk and localized.

Next Step:
- Implement the guarded packages and Homebrew additions, then run `darwin-rebuild switch --flake .#sansa`.
