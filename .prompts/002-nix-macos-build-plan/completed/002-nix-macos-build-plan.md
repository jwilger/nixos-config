<objective>
Create an actionable plan to make the macOS (sansa) nix-darwin build succeed quickly by avoiding Swift/.NET builds, while keeping the configuration aligned with Linux where possible.
</objective>

<context>
Research output: @.prompts/001-nix-macos-build-research/nix-macos-build-research.md
Repository: /Users/jwilger/nixos-config
Constraints:
- Prefer binary caches
- OK to disable or replace heavy packages on macOS
- Use Homebrew for marksman, dotnet, and Swift toolchain on macOS
</context>

<requirements>
1. Provide a step-by-step plan with discrete changes.
2. Specify exact files and options to change.
3. Include macOS-only guards for heavy packages in Home Manager.
4. Use Homebrew replacements where requested.
5. Include updates to flake checks to skip Linux-only outputs on macOS.
6. Keep plan small and safe; avoid broad refactors.
</requirements>

<output>
Write a plan to:
  .prompts/002-nix-macos-build-plan/nix-macos-build-plan.md

The plan MUST include the following XML metadata sections:
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
- Plan references the research and matches constraints
- Clear list of edits and commands to run
- Includes macOS-only guards for heavy packages
</success_criteria>
