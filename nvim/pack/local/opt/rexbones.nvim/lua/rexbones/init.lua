local lush = require 'lush'
local generator = require 'zenbones.specs'

local M = {}

function M.apply(name)
  local palettes = require('rexbones.palettes.' .. name)
  local background = vim.o.background
  if not palettes[background] then
    background = palettes.dark and 'dark' or 'light'
  end
  local p = palettes[background]

  vim.cmd 'highlight clear'
  vim.g.colors_name = name
  vim.o.background = background

  local config = generator.get_global_config(name, background)
  local specs = generator.generate(p, background, config)

  -- Copied from petrolbones: syntax comes directly from Zenbones.
  local extended = lush.extends({ specs }).with(function()
    return {
      FloatBorder { specs.FloatBorder, fg = p.bg1 },
      helpHyperTextJump { fg = p.leaf },
      helpOption { helpHyperTextJump },
      markdownUrl { helpHyperTextJump },
    }
  end)

  lush(extended, { force_clean = false })
  require('zenbones.term').apply_colors(p)
end

return M
