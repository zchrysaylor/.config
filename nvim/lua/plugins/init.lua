local M = {}

function M.setup()
  -- Hooks must predate the first add() so lockfile bootstraps are covered.
  require('plugins.hooks').setup()
  -- Setup stays explicit in Lua modules, so source plugin runtime scripts now.
  vim.pack.add(require 'plugins.specs', { load = true })

  -- The colorscheme runs first; other modules can assume all plugins exist.
  require('plugins.colorscheme').setup()
  require('plugins.integrations').setup()
  require('plugins.ui').setup()
  require('plugins.treesitter').setup()
  require('plugins.telescope').setup()
  require('plugins.oil').setup()
  require('plugins.navigation').setup()
  require('plugins.completion').setup()
  require('plugins.formatting').setup()
  require('plugins.java').setup()
  require('plugins.lsp').setup()
  require('plugins.love2d').setup()
  require('plugins.no-neck-pain').setup()
  require('custom.plugins.todo').setup()
end

return M
