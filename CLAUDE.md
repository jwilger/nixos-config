# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Common Commands

### System Management

**Note**: Claude cannot execute `sudo` commands. After making configuration changes, the user must manually run the rebuild commands below.

- `sudo nixos-rebuild switch --flake .` - Apply configuration changes and switch to new generation (user must run)
- `sudo nixos-rebuild switch --flake .#gregor` - Apply configuration for specific host (gregor) (user must run)
- `sudo nixos-rebuild switch --flake .#vm` - Apply configuration for VM host (user must run)
- `nix flake check` - Validate flake configuration syntax and structure (Claude can run this)
- `nix flake update` - Update all flake inputs to latest versions
- `nix flake show` - Show available configurations and outputs

### Maintenance

- `sudo nix-collect-garbage -d` - Clean up old generations and free disk space
- `nix store optimise` - Deduplicate identical files in the Nix store

## Architecture Overview

This is a NixOS flake-based configuration supporting multiple hosts with a modular structure.

### Flake Structure

- **flake.nix**: Main flake definition with inputs (nixpkgs, home-manager, hyprland, catppuccin)
- **hosts/**: Host-specific configurations
  - `gregor/`: Primary desktop machine with full desktop environment
  - `vm/`: Virtual machine configuration
- **modules/**: Reusable configuration modules
  - `core/`: Essential system components (bootloader, network, security, etc.)
  - `desktop/`: Desktop environment setup (Hyprland, fonts, theming)
  - `home/`: Home Manager configurations for user-specific settings

### Key Design Patterns

- All hosts inherit from `modules/core` for base system functionality
- Desktop hosts additionally import `modules/desktop` for GUI components
- Home Manager configurations are host-specific via `home-manager.users.${username}.imports`
- Catppuccin theme system is used consistently across system and user configs
- Each module is focused on a single concern (git, nvim, zsh, etc.)

### Host Configuration

- **gregor**: Performance-optimized desktop with AMD graphics, Docker, BcacheFS scrubbing
- **vm**: Minimal configuration for virtual machine testing
- Both use username "jwilger" and x86_64-linux architecture

### Theme System

- Catppuccin "mocha" flavor with "lavender" accent color
- Applied at both system level (desktop module) and user level (home modules)
- Consistent across all applications (nvim, bat, starship, etc.)

### Development Environment

- Neovim with LazyVim configuration in `modules/home/nvim/`
- Shell setup with zsh, starship prompt, and zellij multiplexer
- Git configuration with user-specific settings
- Terminal applications: yazi (file manager), btop (system monitor), bat (cat replacement)

# context-mode — MANDATORY routing rules

You have context-mode MCP tools available. These rules are NOT optional — they protect your context window from flooding. A single unrouted command can dump 56 KB into context and waste the entire session.

## BLOCKED commands — do NOT attempt these

### curl / wget — BLOCKED
Any Bash command containing `curl` or `wget` is intercepted and replaced with an error message. Do NOT retry.
Instead use:
- `ctx_fetch_and_index(url, source)` to fetch and index web pages
- `ctx_execute(language: "javascript", code: "const r = await fetch(...)")` to run HTTP calls in sandbox

### Inline HTTP — BLOCKED
Any Bash command containing `fetch('http`, `requests.get(`, `requests.post(`, `http.get(`, or `http.request(` is intercepted and replaced with an error message. Do NOT retry with Bash.
Instead use:
- `ctx_execute(language, code)` to run HTTP calls in sandbox — only stdout enters context

### WebFetch — BLOCKED
WebFetch calls are denied entirely. The URL is extracted and you are told to use `ctx_fetch_and_index` instead.
Instead use:
- `ctx_fetch_and_index(url, source)` then `ctx_search(queries)` to query the indexed content

## REDIRECTED tools — use sandbox equivalents

### Bash (>20 lines output)
Bash is ONLY for: `git`, `mkdir`, `rm`, `mv`, `cd`, `ls`, `npm install`, `pip install`, and other short-output commands.
For everything else, use:
- `ctx_batch_execute(commands, queries)` — run multiple commands + search in ONE call
- `ctx_execute(language: "shell", code: "...")` — run in sandbox, only stdout enters context

### Read (for analysis)
If you are reading a file to **Edit** it → Read is correct (Edit needs content in context).
If you are reading to **analyze, explore, or summarize** → use `ctx_execute_file(path, language, code)` instead. Only your printed summary enters context. The raw file content stays in the sandbox.

### Grep (large results)
Grep results can flood context. Use `ctx_execute(language: "shell", code: "grep ...")` to run searches in sandbox. Only your printed summary enters context.

## Tool selection hierarchy

1. **GATHER**: `ctx_batch_execute(commands, queries)` — Primary tool. Runs all commands, auto-indexes output, returns search results. ONE call replaces 30+ individual calls.
2. **FOLLOW-UP**: `ctx_search(queries: ["q1", "q2", ...])` — Query indexed content. Pass ALL questions as array in ONE call.
3. **PROCESSING**: `ctx_execute(language, code)` | `ctx_execute_file(path, language, code)` — Sandbox execution. Only stdout enters context.
4. **WEB**: `ctx_fetch_and_index(url, source)` then `ctx_search(queries)` — Fetch, chunk, index, query. Raw HTML never enters context.
5. **INDEX**: `ctx_index(content, source)` — Store content in FTS5 knowledge base for later search.

## Subagent routing

When spawning subagents (Agent/Task tool), the routing block is automatically injected into their prompt. Bash-type subagents are upgraded to general-purpose so they have access to MCP tools. You do NOT need to manually instruct subagents about context-mode.

## Output constraints

- Keep responses under 500 words.
- Write artifacts (code, configs, PRDs) to FILES — never return them as inline text. Return only: file path + 1-line description.
- When indexing content, use descriptive source labels so others can `ctx_search(source: "label")` later.

## ctx commands

| Command | Action |
|---------|--------|
| `ctx stats` | Call the `ctx_stats` MCP tool and display the full output verbatim |
| `ctx doctor` | Call the `ctx_doctor` MCP tool, run the returned shell command, display as checklist |
| `ctx upgrade` | Call the `ctx_upgrade` MCP tool, run the returned shell command, display as checklist |
