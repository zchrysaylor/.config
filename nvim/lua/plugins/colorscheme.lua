local M = {}

function M.setup()
  vim.o.termguicolors = true
  vim.cmd.packadd 'rexbones.nvim'
  vim.cmd.colorscheme 'petrolbones'
end

return M
