-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
vim.g.autoformat = true
vim.g.snacks_animate = true
vim.g.markdown_recommended_style = 0

local opt = vim.opt
opt.autowrite = true -- Enable auto write
opt.backup = false
opt.relativenumber = false -- Relative line numbers
opt.scrolloff = 20 -- Lines of context
opt.sidescrolloff = 8 -- Columns of context
opt.smoothscroll = true
