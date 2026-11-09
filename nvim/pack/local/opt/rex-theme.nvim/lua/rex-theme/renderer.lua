local M = {}

-- Adapt ANSI colors to TokyoNight's semantic palette, including derived colors
-- that upstream computes before calling on_colors.
local function apply_palette(colors, palette)
  local Util = require 'tokyonight.util'
  local t = palette.terminal
  -- ANSI black/white may stay dark/light even when the terminal background flips.
  -- Derive neutral UI colors from the actual text colors instead.
  local bg_dark = Util.blend(palette.background, vim.o.background == 'light' and 0.96 or 0.8, '#000000')
  local fg_dark = Util.blend(palette.foreground, 0.8, palette.background)
  local comment = Util.blend(palette.foreground, 0.65, palette.background)
  local gutter = Util.blend(palette.foreground, 0.4, palette.background)
  local mapped = {
    bg = palette.background,
    fg = palette.foreground,
    fg_dark = fg_dark,
    bg_dark = bg_dark,
    bg_dark1 = bg_dark,
    bg_highlight = Util.blend(palette.foreground, 0.08, palette.background),
    red = t.red,
    green = t.green,
    yellow = t.yellow,
    blue = t.blue,
    magenta = t.magenta,
    cyan = t.cyan,
    blue0 = t.blue_bright,
    blue1 = t.cyan_bright,
    blue2 = t.blue,
    blue5 = t.cyan,
    blue6 = t.cyan_bright,
    blue7 = Util.blend(t.blue, 0.5, palette.background),
    comment = comment,
    dark3 = comment,
    dark5 = fg_dark,
    fg_gutter = gutter,
    green1 = t.green_bright,
    green2 = t.green,
    magenta2 = t.magenta_bright,
    orange = t.yellow_bright,
    purple = t.magenta,
    red1 = t.red_bright,
    teal = t.cyan,
    terminal_black = gutter,
    git = { add = t.green_bright, change = t.blue_bright, delete = t.red_bright, ignore = comment },
    diff = {
      add = Util.blend(t.green, 0.15, palette.background),
      delete = Util.blend(t.red, 0.15, palette.background),
      change = Util.blend(t.blue, 0.15, palette.background),
      text = t.blue,
    },
    black = bg_dark,
    border_highlight = Util.blend(t.blue, 0.8, palette.background),
    border = bg_dark,
    bg_popup = bg_dark,
    bg_statusline = bg_dark,
    bg_sidebar = bg_dark,
    bg_float = bg_dark,
    bg_visual = palette.selection_background,
    bg_search = Util.blend(t.blue_bright, 0.2, palette.background),
    fg_sidebar = fg_dark,
    fg_float = palette.foreground,
    error = t.red_bright,
    todo = t.blue,
    warning = t.yellow,
    info = t.blue,
    hint = t.cyan,
    rainbow = { t.blue, t.yellow, t.green, t.cyan, t.magenta, t.magenta_bright, t.yellow_bright, t.red },
    terminal = t,
  }
  for name, color in pairs(mapped) do
    colors[name] = color
  end
  Util.bg = palette.background
  Util.fg = palette.foreground
end

function M.apply(palette, name)
  local background = palette and palette.background or '#1a1b26'
  local r, g, b = background:match '^#(%x%x)(%x%x)(%x%x)$'
  local brightness = tonumber(r, 16) * 0.299 + tonumber(g, 16) * 0.587 + tonumber(b, 16) * 0.114
  vim.g.colors_name = nil
  vim.o.background = brightness > 128 and 'light' or 'dark'
  vim.cmd 'highlight clear'
  -- Pass per-load options instead of setup() so Rex never changes the user's
  -- ordinary TokyoNight configuration. Select day explicitly for light palettes.
  require('tokyonight').load {
    style = vim.o.background == 'light' and 'day' or 'night',
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
      if palette then
        apply_palette(colors, palette)
      else
        local Util = require 'tokyonight.util'
        colors.bg_visual = Util.blend_bg(colors.blue, 0.35)
      end
    end,
    on_highlights = function(highlights)
      if palette then
        highlights.Cursor = { fg = palette.cursor_text, bg = palette.cursor }
        highlights.lCursor = { fg = palette.cursor_text, bg = palette.cursor }
        highlights.TermCursor = { fg = palette.cursor_text, bg = palette.cursor }
        highlights.CursorIM = { fg = palette.cursor_text, bg = palette.cursor }
        highlights.Visual = { fg = palette.selection_foreground, bg = palette.selection_background }
      end
    end,
  }
  vim.g.colors_name = name or 'rex'
end

return M
