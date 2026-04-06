# Nix macOS build research (sansa)

## Executive summary
The nix-darwin build for `sansa` pulls all Home Manager packages from `modules/home/packages.nix`, including the `helixTooling` list. Two entries in that list are the most likely sources of the heavy Swift/.NET builds on macOS: `pkgs.lldb` (Swift toolchain dependency on Darwin) and `pkgs.marksman` (dotnet dependency). Both are unconditional today, so they are evaluated and built on aarch64-darwin. The most practical fix is to make these two packages macOS-conditional (remove or replace with Homebrew), while keeping the rest of the tooling list intact for Linux parity.

## What is included on macOS today
`hosts/sansa/default.nix` imports `modules/home` and `modules/home/darwin`, so Home Manager installs:

- `modules/home/packages.nix` (cross-platform + `helixTooling` list)
- `modules/home/btop.nix` (Linux-only add-on already guarded)
- `modules/home/darwin/packages.nix` (empty list today)

That means all items in `helixTooling` are pulled in on macOS unless explicitly guarded.

## Package graph mapping (Swift and .NET)

### Swift build trigger
**Primary trigger:** `pkgs.lldb` from `helixTooling` in `modules/home/packages.nix`.

- On aarch64-darwin, Nixpkgs’ `lldb` is built from LLVM sources and typically enables Swift language plugins, which brings in `swift` / `swift-5.10.1` as a build-time dependency.
- This aligns with the reported failure in `swift-5.10.1` during nix-darwin builds.

**Graph sketch:**
`home.packages` -> `helixTooling` -> `lldb` -> `llvmPackages` -> `swift-5.10.1`

### .NET build trigger
**Primary trigger:** `pkgs.marksman` from `helixTooling` in `modules/home/packages.nix`.

- `marksman` is commonly packaged in Nixpkgs with a .NET build/runtime dependency (dotnet-sdk / dotnet-runtime) on macOS.
- This matches the known issue: “dotnet and marksman pulled in by Home Manager packages.”

**Graph sketch:**
`home.packages` -> `helixTooling` -> `marksman` -> `dotnet-sdk` (build) + `dotnet-runtime` (runtime)

## macOS incompatibilities and current guards

- Linux-only packages are already guarded in `modules/home/packages.nix` and `modules/home/btop.nix` via `lib.optionals pkgs.stdenv.isLinux`.
- Desktop-only modules (`modules/home/desktop/*`) are not imported in `modules/home/default.nix` for macOS, so `discord`, `pavucontrol`, `gpu-screen-recorder`, etc. are not pulled into `sansa`.
- The macOS-specific module `modules/home/darwin/aerospace.nix` is safe; it relies on Homebrew for the actual app and does not trigger heavy Nix builds.

## Practical avoidance strategies

### 1) Replace with Homebrew on macOS (highest impact, minimal risk)
Move macOS tooling for the heavy packages to Homebrew:

- **marksman**: available via Homebrew; install via `homebrew.brews` and remove from Nix on macOS.
- **lldb**: either rely on Xcode/Command Line Tools `lldb` or install `llvm` via Homebrew (provides `lldb`).

This keeps Linux parity while avoiding Nix builds on macOS.

### 2) Conditional guards in Nix (simple and safe)
Guard only the two problematic packages on macOS:

- Keep `helixTooling` list mostly cross-platform.
- Add a conditional for `lldb` and `marksman` so they are only included on Linux (or excluded on Darwin).

This stops Swift/.NET builds while preserving other language servers.

### 3) Binary caches (low confidence for Swift on aarch64-darwin)
The current nix-darwin config uses only `https://cache.nixos.org`. Swift builds on aarch64-darwin are frequently cache-missing. A secondary cache (e.g., `nix-community.cachix.org`) might help with dotnet-related derivations but is unlikely to consistently cover Swift. Treat this as optional and not a primary solution.

## Minimal, safe changes (recommended)

1) **Guard `marksman` and `lldb` in `modules/home/packages.nix`**
   - Keep all other `helixTooling` entries unchanged.
   - Add Darwin exceptions to avoid Swift/.NET on macOS.

2) **Add Homebrew replacements for macOS**
   - `homebrew.brews = [ "marksman" "llvm" ];` (if you want `lldb` on macOS)
   - If you are ok with Xcode’s `lldb`, only add `marksman`.

This results in zero functional changes for Linux while eliminating the heavy macOS builds.

## Concrete implementation notes

- `modules/home/packages.nix` is where the build triggers are introduced.
- `modules/darwin/homebrew.nix` is already set up; add `marksman` and optionally `llvm` there.
- If you want `marksman` only on Linux, use `lib.optionals pkgs.stdenv.isLinux [ marksman ]`.
- If you want it on both platforms but not via Nix on macOS, split the list:
  - Linux: keep in Nix list
  - macOS: install via Homebrew

## Suggested verification (optional)
Run after applying guards to confirm the dependency drop:

```bash
nix why-depends .#darwinConfigurations.sansa.system pkgs.swift
nix why-depends .#darwinConfigurations.sansa.system pkgs.dotnet-sdk
```

If these commands report no dependency path, the build triggers are removed.

<confidence>
Medium. The package mapping is inferred from the configuration and known Nixpkgs behavior on Darwin; exact dependency paths should be confirmed with `nix why-depends` on the target machine.
</confidence>

<dependencies>
- modules/home/packages.nix (helixTooling list)
- modules/darwin/homebrew.nix (macOS brew replacements)
- hosts/sansa/default.nix (Home Manager imports)
</dependencies>

<open_questions>
- Do you want `lldb` on macOS at all, or should the system rely on Xcode/CLT `lldb`?
- Is Homebrew acceptable for `marksman`, or should it be disabled on macOS entirely?
- Are there any macOS-only editor workflows that require `marksman` specifically?
</open_questions>

<assumptions>
- `lldb` on aarch64-darwin pulls in Swift toolchain dependencies in Nixpkgs.
- `marksman` in Nixpkgs uses dotnet build/runtime on macOS.
- `modules/home/desktop/*` is not imported for the macOS host.
</assumptions>
