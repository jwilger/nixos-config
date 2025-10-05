return {
  "folke/sidekick.nvim",
  dependencies = { "coder/claudecode.nvim" },
  opts = {
    cli = {
      tools = {
        claude = {
          cmd = {
            "claude",
            "--append-system-prompt",
            vim.fn.expand("~/.claude/system-prompt.md"),
            "--dangerously-skip-permissions",
          },
          env = {
            CLAUDE_CODE_SSE_PORT = vim.fn
              .system(string.format("cat %s/claudecode_port 2>/dev/null || echo ''", vim.fn.stdpath("cache")))
              :gsub("%s+$", ""),
            ENABLE_IDE_INTEGRATION = "true",
            FORCE_CODE_TERMINAL = "true",
          },
        },
      },
      win = {
        layout = "right",
        split = { width = 80, height = 20 },
        float = { width = 0.9, height = 0.9 },
      },
    },
    nes = {
      enabled = true,
      debounce = 100,
      diff = {
        inline = "words",
      },
    },
    signs = {
      enabled = true,
      icon = " ",
    },
    jump = {
      jumplist = true,
    },
  },
}
