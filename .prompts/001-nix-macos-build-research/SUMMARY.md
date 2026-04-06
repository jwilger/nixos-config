One-liner: Swift/.NET builds on macOS are triggered by `lldb` and `marksman` in the shared Helix tooling list; guard or move them to Homebrew to avoid heavy builds.
Version: 1.0.0

Key Findings
- `modules/home/packages.nix` unconditionally adds `helixTooling` to macOS; this includes `lldb` and `marksman`.
- `lldb` on aarch64-darwin likely pulls in `swift-5.10.1` via LLVM, matching the Swift build failure.
- `marksman` pulls in dotnet build/runtime dependencies, matching the dotnet build issue.
- macOS already avoids Linux-only desktop packages; only these two tools are problematic for heavy builds.

Decisions Needed
- Should macOS use Homebrew `marksman` and `llvm` (for `lldb`), or disable those tools entirely on macOS?

Blockers
- None for implementing guards; optional confirmation via `nix why-depends` if you want proof of dependency removal.

Next Step
- Add macOS guards for `lldb` and `marksman` in `modules/home/packages.nix` and, if desired, add Homebrew replacements in `modules/darwin/homebrew.nix`.
