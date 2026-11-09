local root = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h:h')

local function equal(actual, expected, label)
  assert(vim.deep_equal(actual, expected), label .. ': expected ' .. vim.inspect(expected) .. ', got ' .. vim.inspect(actual))
end

local function highlight(name)
  return vim.api.nvim_get_hl(0, { name = name, link = false })
end

local function color(hex)
  return tonumber(hex:sub(2), 16)
end

local function terminal_colors()
  local colors = {}
  for i = 0, 15 do
    colors[i + 1] = vim.g['terminal_color_' .. i]
  end
  return colors
end

local function run()
  vim.o.termguicolors = true
  vim.cmd.packadd 'lush.nvim'
  vim.cmd.packadd 'zenbones.nvim'

  local legacy = vim.env.REXBONES_PETROLBONES
  local original_highlights, original_terminal
  if legacy then
    vim.opt.runtimepath:prepend(legacy)
    vim.cmd.colorscheme 'petrolbones'
    original_highlights = vim.api.nvim_get_hl(0, {})
    original_terminal = terminal_colors()
    vim.opt.runtimepath:remove(legacy)
    vim.opt.runtimepath:remove(legacy .. '/after')
  end

  vim.opt.runtimepath:prepend(root)
  vim.cmd.colorscheme 'petrolbones'
  if legacy then
    equal(vim.api.nvim_get_hl(0, {}), original_highlights, 'Petrolbones highlight parity')
    equal(terminal_colors(), original_terminal, 'Petrolbones embedded terminal parity')
  end

  local sources = {}
  if vim.env.REXBONES_REX_THEMES then
    local content = table.concat(vim.fn.readfile(vim.env.REXBONES_REX_THEMES), '\n')
    for _, theme in ipairs(vim.json.decode(content)) do
      sources[theme.id] = theme
    end
  end

  local themes = require 'rexbones.themes'
  local names = vim.tbl_keys(themes)
  table.sort(names)
  equal(#names, 39, 'Colorscheme count')
  equal(#vim.fn.glob(root .. '/colors/*.lua', false, true), #names, 'Entrypoint count')
  equal(#vim.fn.glob(root .. '/lua/rexbones/palettes/*.lua', false, true), #names, 'Palette module count')

  local variants = 0
  local covered = {}
  local term = require 'zenbones.term'
  local terminal_order = {
    'black',
    'red',
    'green',
    'yellow',
    'blue',
    'magenta',
    'cyan',
    'white',
    'bright_black',
    'bright_red',
    'bright_green',
    'bright_yellow',
    'bright_blue',
    'bright_magenta',
    'bright_cyan',
    'bright_white',
  }

  for _, name in ipairs(names) do
    local palettes = require('rexbones.palettes.' .. name)
    for appearance, id in pairs(themes[name]) do
      variants = variants + 1
      assert(not covered[id], 'Duplicate Rex source: ' .. id)
      covered[id] = true
      local p = assert(palettes[appearance], name .. ' missing ' .. appearance)
      local label = name .. '/' .. appearance

      if vim.env.REXBONES_REX_THEMES then
        local source = assert(sources[id], 'Missing Rex source: ' .. id)
        equal(source.appearance, appearance, label .. ' appearance')
        local s = source.source
        local expected = {
          bg = s.background,
          fg = s.foreground,
          rose = s.ansi[2],
          leaf = s.ansi[3],
          wood = s.ansi[4],
          water = s.ansi[5],
          blossom = s.ansi[6],
          sky = s.ansi[7],
        }
        for slot, hex in pairs(expected) do
          -- Match petrolbones' HSLuv conversion, which rounds H/S/L values.
          equal(p[slot].hex, require('lush').hsluv(hex).hex, label .. ' palette ' .. slot)
        end
      end

      vim.o.background = appearance
      vim.cmd.colorscheme(name)
      equal(vim.g.colors_name, name, label .. ' colors_name')
      equal(vim.o.background, appearance, label .. ' background')
      equal(highlight('Normal').bg, color(p.bg.hex), label .. ' Normal bg')
      equal(highlight('Normal').fg, color(p.fg.hex), label .. ' Normal fg')
      equal(highlight('FloatBorder').fg, color(p.bg1.hex), label .. ' border override')
      for _, group in ipairs { 'helpHyperTextJump', 'helpOption', 'markdownUrl' } do
        equal(highlight(group).fg, color(p.leaf.hex), label .. ' link override ' .. group)
      end
      for _, group in ipairs { 'Statement', 'Function', '@function', '@lsp.type.keyword' } do
        equal(highlight(group).fg, color(p.fg.hex), label .. ' Zenbones syntax ' .. group)
      end
      equal(highlight('Statement').bold, true, label .. ' bold statements')
      equal(highlight('Comment').italic, true, label .. ' italic comments')
      equal(highlight('String').italic, true, label .. ' italic strings')
      equal(highlight('DiagnosticError').fg, color(p.rose.hex), label .. ' error color')
      equal(highlight('DiagnosticWarn').fg, color(p.wood.hex), label .. ' warning color')
      equal(highlight('DiagnosticInfo').fg, color(p.water.hex), label .. ' info color')
      equal(highlight('DiagnosticHint').fg, color(p.blossom.hex), label .. ' hint color')

      local mapped = term.colors_map(p)
      for i, slot in ipairs(terminal_order) do
        equal(vim.g['terminal_color_' .. (i - 1)], mapped[slot].hex, label .. ' terminal ' .. (i - 1))
      end
    end

    if not (palettes.dark and palettes.light) then
      local appearance = palettes.dark and 'dark' or 'light'
      vim.o.background = appearance == 'dark' and 'light' or 'dark'
      vim.cmd.colorscheme(name)
      equal(vim.o.background, appearance, name .. ' single-appearance fallback')
      equal(highlight('Normal').bg, color(palettes[appearance].bg.hex), name .. ' fallback background')
    end
  end

  equal(variants, 41, 'Palette variant count')
  for id in pairs(sources) do
    assert(covered[id], 'Unbundled Rex theme: ' .. id)
  end

  for _, name in ipairs { 'merinobones', 'silverpointbones' } do
    vim.o.background = 'dark'
    vim.cmd.colorscheme(name)
    vim.o.background = 'light'
    equal(highlight('Normal').bg, color(require('rexbones.palettes.' .. name).light.bg.hex), name .. ' live light switch')
    vim.o.background = 'dark'
    equal(highlight('Normal').bg, color(require('rexbones.palettes.' .. name).dark.bg.hex), name .. ' live dark switch')
  end

  vim.g.abyssalbones = { italic_comments = false, italic_strings = false, transparent_background = true }
  vim.cmd.colorscheme 'abyssalbones'
  equal(highlight('Normal').bg, nil, 'Transparent background option')
  assert(not highlight('Comment').italic, 'Comment option was ignored')
  assert(not highlight('String').italic, 'String option was ignored')
  vim.cmd.colorscheme 'basaltbones'
  equal(highlight('String').italic, true, 'Configuration isolation')
  vim.g.abyssalbones = nil
  vim.cmd.colorscheme 'abyssalbones'
  equal(highlight('Normal').bg, color(require('rexbones.palettes.abyssalbones').dark.bg.hex), 'Reload resets transparency')
  equal(highlight('String').italic, true, 'Reload resets string style')

  print(
    'PASS: 39 colorschemes, 41 palettes, background switching, overrides, syntax, terminals, and options'
      .. (legacy and '; original Petrolbones parity' or '')
      .. (vim.env.REXBONES_REX_THEMES and '; exact Rex source coverage' or '')
  )
end

local ok, err = xpcall(run, debug.traceback)
if not ok then
  io.stderr:write(err .. '\n')
  vim.cmd 'cquit 1'
end
