local specs = {
  -- Colorscheme first: its highlights should be in place before other UI setup.
  'https://github.com/nkxxll/ghostty-default-style-dark.nvim',

  -- Libraries and runtime dependencies.
  'https://github.com/nvim-lua/plenary.nvim',
  'https://github.com/MunifTanjim/nui.nvim',
  'https://github.com/mfussenegger/nvim-dap',
  {
    src = 'https://github.com/JavaHello/spring-boot.nvim',
    version = '218c0c26c14d99feca778e4d13f5ec3e8b1b60f0',
  },
  'https://github.com/mason-org/mason.nvim',
  'https://github.com/mason-org/mason-lspconfig.nvim',
  'https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim',
  'https://github.com/neovim/nvim-lspconfig',
  'https://github.com/j-hui/fidget.nvim',
  'https://github.com/folke/lazydev.nvim',
  { src = 'https://github.com/L3MON4D3/LuaSnip', version = vim.version.range '2.x' },
  'https://github.com/nvim-telescope/telescope-ui-select.nvim',

  -- UI and editing.
  'https://github.com/catgoose/nvim-colorizer.lua',
  'https://github.com/NMAC427/guess-indent.nvim',
  'https://github.com/lewis6991/gitsigns.nvim',
  'https://github.com/folke/which-key.nvim',
  { src = 'https://github.com/shortcuts/no-neck-pain.nvim', version = vim.version.range '3.x' },
  'https://github.com/echasnovski/mini.nvim',
  'https://github.com/lukas-reineke/indent-blankline.nvim',
  'https://github.com/windwp/nvim-autopairs',
  'https://github.com/folke/todo-comments.nvim',

  -- LSP, formatting, completion, and language tooling.
  'https://github.com/nvim-java/nvim-java',
  { src = 'https://github.com/S1M0N38/love2d.nvim', version = vim.version.range '2.x' },
  'https://github.com/stevearc/conform.nvim',
  { src = 'https://github.com/saghen/blink.cmp', version = vim.version.range '1.x' },
  { src = 'https://github.com/nvim-treesitter/nvim-treesitter', version = 'main' },

  -- Navigation and search.
  'https://github.com/stevearc/oil.nvim',
  'https://github.com/nvim-telescope/telescope.nvim',
}

if vim.g.have_nerd_font then
  table.insert(specs, 'https://github.com/nvim-tree/nvim-web-devicons')
end

if vim.fn.executable 'make' == 1 then
  table.insert(specs, 'https://github.com/nvim-telescope/telescope-fzf-native.nvim')
end

return specs
