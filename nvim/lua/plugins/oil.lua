local M = {}

function M.setup()
  require('oil').setup {}
  vim.keymap.set('n', '-', '<cmd>Oil<CR>', { desc = 'Open parent directory' })
end

return M
