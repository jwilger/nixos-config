return {
  "coder/claudecode.nvim",
  dependencies = { "folke/snacks.nvim" },
  lazy = false, -- Load immediately to start WebSocket server for /ide integration
  opts = {
    terminal_cmd = 'claude --append-system-prompt "$(cat ~/.claude/system-prompt.md)"',
    focus_after_send = true,
    auto_start = true, -- Ensure WebSocket server starts automatically
    diff_opts = {
      layout = "vertical",
      open_in_new_tab = true,
      keep_terminal_focus = true,
    },
  },
  config = function(_, opts)
    -- Apply options
    require("claudecode").setup(opts)

    -- Track last active non-terminal window
    local last_active_win = nil

    -- Initialize with current window if it's not a terminal
    local current_buf = vim.api.nvim_get_current_buf()
    if vim.bo[current_buf].buftype ~= "terminal" then
      last_active_win = vim.api.nvim_get_current_win()
    end

    -- Write port to file for sidekick to read and send initial context
    vim.schedule(function()
      local claudecode = require("claudecode")
      if claudecode.state and claudecode.state.port then
        local port_file = vim.fn.stdpath("cache") .. "/claudecode_port"
        local f = io.open(port_file, "w")
        if f then
          f:write(tostring(claudecode.state.port))
          f:close()
        end

        -- Hook into client connections to send initial context
        local server = require("claudecode.server")
        if server.state and server.state.callbacks then
          local original_on_connect = server.state.callbacks.on_connect

          server.state.callbacks.on_connect = function(client)
            -- Call original handler
            if original_on_connect then
              original_on_connect(client)
            end

            -- Send initial selection update when client connects
            vim.schedule(function()
              local selection = require("claudecode.selection")
              if selection.server then
                local init_buf = vim.api.nvim_get_current_buf()
                local saved_win = vim.api.nvim_get_current_win()

                -- If currently in terminal, switch to last_active_win temporarily
                if vim.bo[init_buf].buftype == "terminal" and last_active_win and vim.api.nvim_win_is_valid(last_active_win) then
                  vim.api.nvim_set_current_win(last_active_win)
                end

                -- Get and send selection
                local current_mode_info = vim.api.nvim_get_mode()
                local current_mode = current_mode_info.mode
                local current_selection

                if current_mode == "v" or current_mode == "V" or current_mode == "\022" then
                  current_selection = selection.get_visual_selection()
                else
                  current_selection = selection.get_cursor_position()
                end

                selection.state.latest_selection = current_selection
                selection.send_selection_update(current_selection)

                -- Restore window focus if we changed it
                if vim.api.nvim_win_is_valid(saved_win) then
                  vim.api.nvim_set_current_win(saved_win)
                end
              end
            end)
          end
        end
      end
    end)

    -- Defer patching until tools are registered
    vim.schedule(function()
      local tools = require("claudecode.tools")
      if tools.tools and tools.tools["get_current_selection"] then
        local original_handler = tools.tools["get_current_selection"].handler

        tools.tools["get_current_selection"].handler = function(...)
          local current_buf = vim.api.nvim_get_current_buf()

          -- If current buffer is a terminal, use last active non-terminal window
          if vim.bo[current_buf].buftype == "terminal" then
            if last_active_win and vim.api.nvim_win_is_valid(last_active_win) then
              vim.api.nvim_set_current_win(last_active_win)
            else
              -- Fallback: find any non-terminal window
              local wins = vim.tbl_filter(function(w)
                local buf = vim.api.nvim_win_get_buf(w)
                return vim.bo[buf].buftype ~= "terminal"
              end, vim.api.nvim_list_wins())

              if wins[1] then
                vim.api.nvim_set_current_win(wins[1])
              end
            end
          end

          return original_handler(...)
        end
      end

      -- Patch selection tracking to skip terminal buffers
      local selection = require("claudecode.selection")
      if selection.update_selection then
        local original_update = selection.update_selection

        selection.update_selection = function()
          local current_buf = vim.api.nvim_get_current_buf()
          -- Skip selection updates for terminal buffers entirely
          if vim.bo[current_buf].buftype == "terminal" then
            return
          end
          return original_update()
        end

        -- Track last active non-terminal window and force updates
        local augroup = vim.api.nvim_create_augroup("ClaudeCodeTerminalFix", { clear = true })

        -- Track window LEAVING a non-terminal buffer (before switching to terminal)
        vim.api.nvim_create_autocmd("WinLeave", {
          group = augroup,
          callback = function()
            local current_buf = vim.api.nvim_get_current_buf()
            local current_win = vim.api.nvim_get_current_win()

            if vim.bo[current_buf].buftype ~= "terminal" then
              last_active_win = current_win
            end
          end,
        })

        -- Force update when ENTERING a non-terminal window (from terminal)
        vim.api.nvim_create_autocmd("WinEnter", {
          group = augroup,
          callback = function()
            local current_buf = vim.api.nvim_get_current_buf()
            local current_win = vim.api.nvim_get_current_win()

            -- Track non-terminal windows
            if vim.bo[current_buf].buftype ~= "terminal" then
              last_active_win = current_win

              -- Force update when entering a non-terminal window
              if selection.server then
                local current_mode_info = vim.api.nvim_get_mode()
                local current_mode = current_mode_info.mode
                local current_selection

                if current_mode == "v" or current_mode == "V" or current_mode == "\022" then
                  current_selection = selection.get_visual_selection()
                else
                  current_selection = selection.get_cursor_position()
                end

                selection.state.latest_selection = current_selection
                selection.send_selection_update(current_selection)
              end
            end
          end,
        })
      end
    end)
  end,
  keys = {
    -- Diff management only - sidekick handles all other Claude interactions
    { "<leader>aA", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Accept diff" },
    { "<leader>aD", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Deny diff" },
  },
}
