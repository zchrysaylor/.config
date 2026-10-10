return {
  'stevearc/oil.nvim',
  lazy = false,
  dependencies = {
    { 'nvim-tree/nvim-web-devicons', enabled = vim.g.have_nerd_font },
  },
  ---@module 'oil'
  ---@type oil.SetupOpts
  opts = {},
  keys = {
    { '-', '<cmd>Oil<CR>', desc = 'Open parent directory' },
  },
}
