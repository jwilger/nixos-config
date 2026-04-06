<objective>
Identify why nix-darwin builds on macOS are compiling Swift/.NET, map the package graph triggering those builds, and determine the most practical ways to avoid heavy builds on macOS while keeping the configuration usable.
</objective>

<context>
Repository: /Users/jwilger/nixos-config
Target host: sansa (aarch64-darwin)
Known issues:
- Swift build failure in nixpkgs swift-5.10.1
- dotnet and marksman pulled in by Home Manager packages
Relevant files:
- /Users/jwilger/nixos-config/modules/home/packages.nix
- /Users/jwilger/nixos-config/modules/home/btop.nix
- /Users/jwilger/nixos-config/modules/home/darwin/packages.nix
- /Users/jwilger/nixos-config/modules/darwin/homebrew.nix
- /Users/jwilger/nixos-config/flake.nix
- /Users/jwilger/nixos-config/hosts/sansa/default.nix
- /Users/jwilger/nixos-config/modules/home/darwin/aerospace.nix
</context>

<requirements>
1. Identify which package(s) trigger Swift and .NET builds on macOS.
2. Determine which of those packages can be:
   - replaced by Homebrew on macOS
   - disabled on macOS via conditional guards
   - preserved via binary caches (if viable)
3. Confirm which nix-darwin/Home Manager options or packages are macOS-incompatible.
4. Propose minimal, safe changes to avoid heavy builds without breaking core tooling.
5. Prioritize changes that keep Linux parity while allowing macOS exceptions.
6. Keep findings actionable for immediate implementation.
</requirements>

<output>
Write a research report to:
  .prompts/001-nix-macos-build-research/nix-macos-build-research.md

The report MUST include the following XML metadata sections:
<confidence>...</confidence>
<dependencies>...</dependencies>
<open_questions>...</open_questions>
<assumptions>...</assumptions>

Also create a SUMMARY.md in the same folder with:
- One-liner
- Version
- Key Findings
- Decisions Needed
- Blockers
- Next Step
</output>

<success_criteria>
- Clear mapping of packages to Swift/.NET builds
- Concrete list of macOS-specific removals or Homebrew replacements
- Minimal changes with high impact on build time
- Summary includes decisions required from user
</success_criteria>
