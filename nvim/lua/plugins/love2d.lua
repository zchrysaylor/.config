local M = {}

function M.setup()
  require('love2d').setup {}

  vim.keymap.set('n', '<leader>v', '<Nop>', { desc = 'LÖVE' })
  vim.keymap.set('n', '<leader>vv', '<cmd>LoveRun<cr>', { desc = 'Run LÖVE' })
  vim.keymap.set('n', '<leader>vs', '<cmd>LoveStop<cr>', { desc = 'Stop LÖVE' })
end

return M
