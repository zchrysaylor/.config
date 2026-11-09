-- :colorscheme can find an opt package before its Lua modules are on runtimepath.
vim.cmd.packadd 'rex-theme.nvim'

require('rex-theme').activate()
