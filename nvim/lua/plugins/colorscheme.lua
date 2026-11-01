local M = {}

function M.setup()
  require('ghostty-default-style-dark').setup {
    transparent = false,
    terminal_colors = true,
    styles = {
      comments = { italic = true },
      keywords = { italic = true },
      functions = {},
      variables = {},
      sidebars = 'dark',
      floats = 'dark',
    },
    dim_inactive = false,
    lualine_bold = true,
    on_colors = function(colors)
      -- Make visual selections more obvious against the background.
      local Util = require 'ghostty-default-style-dark.util'
      colors.bg_visual = Util.blend_bg(colors.blue, 0.35)
    end,
  }
  vim.cmd.colorscheme 'ghostty-default-style-dark'
  vim.api.nvim_set_hl(0, 'Comment', { fg = '#b8b8b8', italic = false })
end

return M
