return {
  "folke/sidekick.nvim",
  dependencies = { "coder/claudecode.nvim" },
  opts = {
    clis = {
      claude = {
        cmd = {
          "sh",
          "-c",
          string.format(
            'CLAUDE_CODE_SSE_PORT="$(cat %s/claudecode_port 2>/dev/null || echo \'\')" ' ..
            'ENABLE_IDE_INTEGRATION=true FORCE_CODE_TERMINAL=true ' ..
            'claude --append-system-prompt "$(cat ~/.claude/system-prompt.md)"',
            vim.fn.stdpath("cache")
          ),
        },
      },
    },
    cli = {
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
