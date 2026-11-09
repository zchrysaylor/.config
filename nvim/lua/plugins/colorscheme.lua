local M = {}

function M.setup()
  vim.o.termguicolors = true
  vim.cmd.packadd 'rexbones.nvim'
  vim.cmd.colorscheme 'petrolbones'
  require('rexbones').setup { auto_sync = true }
end

return M
