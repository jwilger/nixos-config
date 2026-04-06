<objective>
Implement the planned changes to make nix-darwin builds succeed on macOS by avoiding Swift/.NET builds and using Homebrew where appropriate.
</objective>

<context>
Plan: @.prompts/002-nix-macos-build-plan/nix-macos-build-plan.md
Repository: /Users/jwilger/nixos-config
Target host: sansa (aarch64-darwin)
Preferences:
- Prefer binary caches
- OK to disable/replace heavy packages on macOS
- Use Homebrew for marksman, dotnet, Swift toolchain
</context>

<requirements>
1. Apply the changes from the plan directly to the repo.
2. Add macOS guards for heavy packages that cause Swift/.NET builds.
3. Move macOS replacements into Homebrew configuration where needed.
4. Adjust flake checks to skip Linux-only outputs when running on macOS.
5. Keep Linux behavior unchanged unless explicitly required.
6. Do not run destructive git commands or commits.
</requirements>

<output>
- Implement changes in the repository.
- Create a SUMMARY.md in:
  .prompts/003-nix-macos-build-do/SUMMARY.md

SUMMARY.md must include:
- One-liner
- Version
- Files Created
- Decisions Needed
- Blockers
- Next Step
</output>

<success_criteria>
- macOS nix-darwin build avoids Swift/.NET compilation
- Homebrew installs replacements where requested
- flake check workflow is macOS-friendly
- Changes are minimal and targeted
</success_criteria>
