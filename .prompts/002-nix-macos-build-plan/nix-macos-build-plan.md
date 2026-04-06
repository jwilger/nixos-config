# Nix macOS build plan (sansa)

Objective: make the `sansa` nix-darwin build succeed quickly by avoiding Swift/.NET builds, while keeping Linux parity. This plan follows the research in `.prompts/001-nix-macos-build-research/nix-macos-build-research.md` and keeps changes minimal.

## Plan
1) Guard heavy HM packages on macOS (lldb, marksman)
   - File: `modules/home/packages.nix`
   - Change: move `lldb` and `marksman` out of the unconditional `helixTooling` list, then re-add them only for Linux.
   - Suggested shape:
     - Keep `helixTooling` as a base list without `lldb` and `marksman`.
     - Append `lib.optionals pkgs.stdenv.isLinux [ lldb marksman ]` to keep Linux parity.
   - Outcome: stops Swift and .NET toolchain builds on macOS while preserving Linux behavior.

2) Add Homebrew replacements for macOS
   - File: `modules/darwin/homebrew.nix`
   - Change: add required formulae/casks to Homebrew for macOS equivalents.
   - Add to `homebrew.brews`:
     - `"marksman"` (markdown LSP)
     - `"dotnet"` (dotnet SDK/runtime)
     - `"llvm"` (optional, provides `lldb` without Nix Swift toolchain builds)
   - Add to `homebrew.casks` (Swift toolchain):
     - `"swift"` (swift.org toolchain cask)
   - Outcome: macOS gets marksman/dotnet/Swift toolchain from Homebrew, avoiding Nix builds.

3) Keep macOS-only guards explicit in Home Manager
   - File: `modules/home/packages.nix`
   - Change: add comments near the Linux-only `helixTooling` additions explaining that macOS uses Homebrew for these tools.
   - Outcome: future maintainers understand why the guards exist and where macOS gets replacements.

4) Add flake checks with OS-specific guards
   - File: `flake.nix`
   - Change: add a `checks` output that only includes Linux checks on Linux systems and Darwin checks on macOS.
   - Suggested structure (minimal, safe):
     - `checks = nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" ] (system: let pkgs = import nixpkgs { inherit system; }; in (nixpkgs.lib.optionalAttrs pkgs.stdenv.isLinux { nixos-gregor = self.nixosConfigurations.gregor.config.system.build.toplevel; nixos-vm = self.nixosConfigurations.vm.config.system.build.toplevel; }) // (nixpkgs.lib.optionalAttrs pkgs.stdenv.isDarwin { darwin-sansa = self.darwinConfigurations.sansa.system; darwin-darwin = self.darwinConfigurations.darwin.system; }));`
   - Outcome: `nix flake check` won’t attempt Linux-only outputs on macOS, and vice versa.

## Commands to run
- Apply configuration:
  - `darwin-rebuild switch --flake .#sansa`
- Verify dependency removal (optional):
  - `nix why-depends .#darwinConfigurations.sansa.system pkgs.swift`
  - `nix why-depends .#darwinConfigurations.sansa.system pkgs.dotnet-sdk`
- Run checks (post-change):
  - `nix flake check --system aarch64-darwin`

<confidence>
Medium. The dependency chain for `lldb` and `marksman` on aarch64-darwin is inferred but well-aligned with Nixpkgs behavior; `nix why-depends` should confirm removal.
</confidence>

<dependencies>
- `modules/home/packages.nix` (helixTooling list)
- `modules/darwin/homebrew.nix` (Homebrew replacements)
- `flake.nix` (add checks with OS guards)
</dependencies>

<open_questions>
- Confirm whether `llvm` via Homebrew is preferred for `lldb` on macOS or if Xcode/CLT `lldb` is sufficient.
- Confirm the desired Swift toolchain source: `swift` Homebrew cask vs Xcode/CLT.
</open_questions>

<assumptions>
- Removing `lldb` and `marksman` from macOS Nix packages removes Swift/.NET build triggers.
- Homebrew is allowed on `sansa` for `marksman`, `dotnet`, and Swift toolchain.
</assumptions>
