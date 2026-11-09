local M = {}

function M.setup()
  vim.cmd.packadd 'rex-theme.nvim'
  require('rex-theme').setup()
  vim.cmd.colorscheme 'rex'
end

return M
