return {
  {
    "elixir-tools/elixir-tools.nvim",
    version = "*",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      local elixir = require("elixir")
      local elixirls = require("elixir.elixirls")

      elixir.setup({
        nextls = {
          enable = true,
          spitfire = true,
          extensions = {
            credo = {
              enable = true,
            },
          },
          init_options = {
            experimental = {
              completions = {
                enable = true,
              },
            },
          },
        },
        elixirls = {
          enable = true,
          settings = elixirls.settings({
            dialyzerEnabled = false,
            enableTestLenses = false,
          }),
        },
        projectionist = {
          enable = true,
        },
      })
    end,
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
  },
}
