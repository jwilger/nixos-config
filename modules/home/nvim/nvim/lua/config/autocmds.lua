-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- Close tab when last buffer in it is deleted
vim.api.nvim_create_autocmd("BufDelete", {
  callback = function()
    vim.schedule(function()
      local tabs = vim.fn.tabpagenr("$")
      if tabs > 1 then
        local buffers_in_tab = vim.fn.tabpagebuflist()
        if #buffers_in_tab == 1 then
          vim.cmd("tabclose")
        end
      end
    end)
  end,
})
