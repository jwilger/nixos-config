-- WezTerm Configuration - Translated from Zellij Config
local wezterm = require("wezterm")
local config = wezterm.config_builder()
local act = wezterm.action

-- Theme configuration (matching your Catppuccin Mocha)
config.color_scheme = "catppuccin-mocha"

-- Leader key configuration (matching your Ctrl+a tmux-style setup)
config.leader = {
	key = "a",
	mods = "CTRL",
	timeout_milliseconds = 1000,
}

-- Font and UI configuration - cross-platform compatible
config.font = wezterm.font_with_fallback({
	"JetBrainsMono Nerd Font", -- macOS naming
	"JetBrainsMono Nerd Font Mono", -- Linux/NixOS naming  
	"JetBrainsMonoNL Nerd Font", -- Alternative Linux naming
	"JetBrains Mono", -- Fallback without Nerd Font
	"Menlo", -- macOS fallback
	"Consolas", -- Windows fallback
})
config.font_size = 12.0

-- Cursor configuration
config.default_cursor_style = "BlinkingBlock"
config.cursor_blink_rate = 800

config.unix_domains = {
	{
		name = "main",
	},
}

config.ssh_domains = {
	{
		name = "gregor",
		remote_address = "gregor",
		username = "jwilger",
	},
}

-- SSH agent forwarding configuration
-- Test with mux_enable_ssh_agent = true in case recent nightly fixed the issues
config.mux_enable_ssh_agent = true

-- SSH backend for better compatibility
config.ssh_backend = "Ssh2"

-- Tab bar configuration (compact style like your Zellij setup)
config.hide_tab_bar_if_only_one_tab = false
config.tab_bar_at_bottom = false
config.use_fancy_tab_bar = false
config.enable_tab_bar = true
config.show_tab_index_in_tab_bar = true
config.tab_max_width = 32

-- Status updates
config.status_update_interval = 1000

-- Right status (domain and workspace info)
wezterm.on("update-status", function(window, pane)
	local domain = pane:get_domain_name() or "local"
	local workspace = window:active_workspace() or "default"

	-- Create status text with domain and workspace
	local status_text = string.format("🌐 %s | 📁 %s", domain, workspace)

	window:set_right_status(wezterm.format({
		{ Attribute = { Intensity = "Bold" } },
		{ Foreground = { Color = "#cba6f7" } }, -- Catppuccin Mocha lavender
		{ Text = " " .. status_text .. " " },
	}))
end)

-- Window padding and appearance
config.window_padding = {
	left = 2,
	right = 2,
	top = 0,
	bottom = 0,
}

-- Mouse support (matching your mouse_mode true)
config.enable_scroll_bar = false
config.scrollback_lines = 10000

-- Define key tables for modal operations
config.key_tables = {
	-- Locked mode (equivalent to your F12 locked mode)
	locked_mode = {
		{ key = "F12", action = act.PopKeyTable },
	},

	-- Move mode (equivalent to your move mode)
	move_mode = {
		{ key = "h", action = act.ActivatePaneDirection("Left") },
		{ key = "j", action = act.ActivatePaneDirection("Down") },
		{ key = "k", action = act.ActivatePaneDirection("Up") },
		{ key = "l", action = act.ActivatePaneDirection("Right") },
		{ key = "Tab", action = act.PaneSelect },
		{ key = "Enter", action = act.PopKeyTable },
		{ key = "Escape", action = act.PopKeyTable },
	},

	-- Resize mode (equivalent to your resize mode)
	resize_mode = {
		{ key = "h", action = act.AdjustPaneSize({ "Left", 2 }) },
		{ key = "j", action = act.AdjustPaneSize({ "Down", 2 }) },
		{ key = "k", action = act.AdjustPaneSize({ "Up", 2 }) },
		{ key = "l", action = act.AdjustPaneSize({ "Right", 2 }) },
		{ key = "LeftArrow", action = act.AdjustPaneSize({ "Left", 2 }) },
		{ key = "RightArrow", action = act.AdjustPaneSize({ "Right", 2 }) },
		{ key = "UpArrow", action = act.AdjustPaneSize({ "Up", 2 }) },
		{ key = "DownArrow", action = act.AdjustPaneSize({ "Down", 2 }) },
		{ key = "Enter", action = act.PopKeyTable },
		{ key = "Escape", action = act.PopKeyTable },
	},
}

-- Main keybindings (clear defaults like your clear-defaults=true)
config.disable_default_key_bindings = false

config.keys = {
	-- F12 for locked mode (matching your F12 binding)
	{ key = "F12", action = act.ActivateKeyTable({ name = "locked_mode", one_shot = false }) },

	-- Session manager equivalent (your 's' binding with session-manager plugin)
	{ key = "s", mods = "LEADER", action = act.ShowLauncherArgs({ flags = "WORKSPACES" }) },

	-- Domain selector (similar to leader-s but for domains/SSH workspaces)
	{ key = "S", mods = "LEADER", action = act.ShowLauncherArgs({ flags = "DOMAINS" }) },

	-- Create new workspace (your 'w' binding equivalent)
	{
		key = "w",
		mods = "LEADER",
		action = act.PromptInputLine({
			description = "Enter name for new workspace",
			action = wezterm.action_callback(function(window, pane, line)
				if line then
					window:perform_action(act.SwitchToWorkspace({ name = line }), pane)
				end
			end),
		}),
	},

	-- Rename current workspace
	{
		key = "$",
		mods = "LEADER|SHIFT",
		action = act.PromptInputLine({
			description = "Enter new name for current workspace",
			action = wezterm.action_callback(function(window, pane, line)
				if line then
					window:perform_action(
						act.SwitchToWorkspace({
							name = line,
							spawn = {
								domain = "CurrentPaneDomain",
							},
						}),
						pane
					)
				end
			end),
		}),
	},

	-- Scroll mode (your '[' binding)
	{ key = "[", mods = "LEADER", action = act.ActivateCopyMode },

	-- Send Ctrl+a to terminal (your "Ctrl a" { Write 1; } binding)
	{ key = "a", mods = "LEADER|CTRL", action = act.SendKey({ key = "a", mods = "CTRL" }) },

	-- Pane splitting (your '\' for right, '-' for down)
	{ key = "\\", mods = "LEADER", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
	{ key = "-", mods = "LEADER", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },

	-- Toggle fullscreen (your 'z' binding)
	{ key = "z", mods = "LEADER", action = act.TogglePaneZoomState },

	-- New tab (your 'c' binding)
	{ key = "c", mods = "LEADER", action = act.SpawnTab("CurrentPaneDomain") },

	-- Rename tab (your ',' binding)
	{
		key = ",",
		mods = "LEADER",
		action = act.PromptInputLine({
			description = "Enter new name for tab",
			action = wezterm.action_callback(function(window, pane, line)
				if line then
					window:active_tab():set_title(line)
				end
			end),
		}),
	},

	-- Toggle between last two tabs (your 'i' binding - ToggleTab)
	{ key = "i", mods = "LEADER", action = act.ActivateLastTab },

	-- Previous/Next tab (your 'p'/'n' bindings)
	{ key = "p", mods = "LEADER", action = act.ActivateTabRelative(-1) },
	{ key = "n", mods = "LEADER", action = act.ActivateTabRelative(1) },

	-- Pane navigation (your hjkl bindings)
	{ key = "h", mods = "LEADER", action = act.ActivatePaneDirection("Left") },
	{ key = "j", mods = "LEADER", action = act.ActivatePaneDirection("Down") },
	{ key = "k", mods = "LEADER", action = act.ActivatePaneDirection("Up") },
	{ key = "l", mods = "LEADER", action = act.ActivatePaneDirection("Right") },

	-- Cycle layouts (your Space binding for NextSwapLayout)
	-- WezTerm doesn't have predefined layouts, so we'll use pane selection instead
	{ key = "Space", mods = "LEADER", action = act.PaneSelect },

	-- Close pane (your 'x' binding)
	{ key = "x", mods = "LEADER", action = act.CloseCurrentPane({ confirm = true }) },

	-- Toggle floating panes equivalent (your 'f' binding) - spawn new window
	{ key = "f", mods = "LEADER", action = act.SpawnWindow },

	-- Tab switching by number (your 1-9 bindings)
	{ key = "1", mods = "LEADER", action = act.ActivateTab(0) },
	{ key = "2", mods = "LEADER", action = act.ActivateTab(1) },
	{ key = "3", mods = "LEADER", action = act.ActivateTab(2) },
	{ key = "4", mods = "LEADER", action = act.ActivateTab(3) },
	{ key = "5", mods = "LEADER", action = act.ActivateTab(4) },
	{ key = "6", mods = "LEADER", action = act.ActivateTab(5) },
	{ key = "7", mods = "LEADER", action = act.ActivateTab(6) },
	{ key = "8", mods = "LEADER", action = act.ActivateTab(7) },
	{ key = "9", mods = "LEADER", action = act.ActivateTab(8) },

	-- Edit scrollback (your 'e' binding)
	{ key = "e", mods = "LEADER", action = act.QuickSelect },

	-- Move mode (your 'm' binding)
	{ key = "m", mods = "LEADER", action = act.ActivateKeyTable({ name = "move_mode", one_shot = false }) },

	-- Resize mode (your '=' binding)
	{ key = "=", mods = "LEADER", action = act.ActivateKeyTable({ name = "resize_mode", one_shot = false }) },

	-- Quit (your 'q' binding)
	{ key = "q", mods = "LEADER", action = act.QuitApplication },

	-- Lazygit integration (your 'g' binding)
	{
		key = "g",
		mods = "LEADER",
		action = act.SpawnCommandInNewTab({
			label = "lazygit",
			args = { "lazygit" },
			cwd = wezterm.home_dir,
		}),
	},

	-- Copy and paste
	{ key = "v", mods = "LEADER", action = act.PasteFrom("Clipboard") },
	{ key = "y", mods = "LEADER", action = act.ActivateCopyMode },

	-- Reload configuration
	{ key = "r", mods = "LEADER|CTRL", action = act.ReloadConfiguration },

	-- Command palette
	{ key = "p", mods = "LEADER|CTRL", action = act.ActivateCommandPalette },
}

-- Mouse bindings
config.mouse_bindings = {
	-- Right click to paste (matching your mouse_mode true)
	{
		event = { Down = { streak = 1, button = "Right" } },
		mods = "NONE",
		action = act.PasteFrom("Clipboard"),
	},
	-- Change the default click behavior to only select text
	{
		event = { Up = { streak = 1, button = "Left" } },
		mods = "NONE",
		action = act.CompleteSelection("ClipboardAndPrimarySelection"),
	},
	-- Middle click to paste
	{
		event = { Down = { streak = 1, button = "Middle" } },
		mods = "NONE",
		action = act.PasteFrom("PrimarySelection"),
	},
}

-- Return the configuration
return config
