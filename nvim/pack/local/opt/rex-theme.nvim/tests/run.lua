-- Run: TOKYONIGHT_PATH=/path/to/tokyonight.nvim nvim --headless -u NONE -i NONE -l tests/run.lua
local root = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h:h')
vim.opt.runtimepath:prepend(root)
if vim.env.TOKYONIGHT_PATH then
  vim.opt.runtimepath:append(vim.fn.expand(vim.env.TOKYONIGHT_PATH))
end
local has_tokyonight, tokyonight = pcall(require, 'tokyonight')
assert(has_tokyonight, 'Set TOKYONIGHT_PATH to a TokyoNight checkout, or add it to runtimepath before running tests')

local theme = require 'rex-theme'
local cache_directory = vim.fn.tempname()
local Util = require 'tokyonight.util'
local original_cache_file = Util.cache.file
Util.cache.file = function(key)
  return cache_directory .. '/tokyonight-' .. key .. '.json'
end
local cache_file = cache_directory .. '/palette.json'
local original_send, original_uis = vim.api.nvim_ui_send, vim.api.nvim_list_uis
local sent, tty = {}, false
vim.api.nvim_ui_send = function(sequence)
  sent[#sent + 1] = sequence
end
vim.api.nvim_list_uis = function()
  return tty and { { stdout_tty = true } } or {}
end

local function wait_for(predicate)
  assert(vim.wait(500, predicate, 5), 'Timed out waiting for test condition')
end
local function settle()
  vim.wait(50, function()
    return false
  end, 5)
end
local function receive(sequence)
  vim.api.nvim_exec_autocmds('TermResponse', { data = { sequence = sequence } })
end
local function response(code, color)
  local r, g, b = color:match '^#(%x%x)(%x%x)(%x%x)$'
  return ('\027]%s;rgb:%s%s/%s%s/%s%s'):format(code, r, r, g, g, b, b)
end
local ansi = {}
for i = 0, 15 do
  ansi[i + 1] = ('#%02x%02x%02x'):format(i * 11, i * 13, i * 15)
end
local function reply(background, cursor, foreground, terminal)
  for i, color in ipairs(terminal or ansi) do
    receive(response('4;' .. (i - 1), color))
  end
  receive(response('10', foreground or '#c2d8d8'))
  receive(response('11', background or '#0c1618'))
  if cursor then
    receive(response('12', cursor))
  end
end
local function highlight(name, fg, bg)
  local actual = vim.api.nvim_get_hl(0, { name = name, link = false })
  if fg then
    assert(actual.fg == tonumber(fg:sub(2), 16), name .. ' foreground')
  end
  if bg then
    assert(actual.bg == tonumber(bg:sub(2), 16), name .. ' background')
  end
end

local function contrast(name)
  local normal = vim.api.nvim_get_hl(0, { name = 'Normal', link = false })
  local actual = vim.api.nvim_get_hl(0, { name = name, link = false })
  local function luminance(color)
    local total = 0
    for i, weight in ipairs { 0.2126, 0.7152, 0.0722 } do
      local channel = math.floor(color / 256 ^ (3 - i)) % 256 / 255
      total = total + weight * (channel <= 0.04045 and channel / 12.92 or ((channel + 0.055) / 1.055) ^ 2.4)
    end
    return total
  end
  local fg, bg = luminance(actual.fg or normal.fg), luminance(actual.bg or normal.bg)
  local ratio = (math.max(fg, bg) + 0.05) / (math.min(fg, bg) + 0.05)
  assert(ratio >= 4.5, ('%s contrast is %.2f:1, expected at least 4.5:1'):format(name, ratio))
end

-- Save ordinary TokyoNight highlights with a user's own configuration. Rex's
-- per-load callbacks must neither replace this configuration nor leak colors.
tokyonight.setup {
  style = 'night',
  styles = { comments = { italic = false } },
  on_colors = function(colors)
    colors.orange = '#123abc'
  end,
  on_highlights = function(highlights)
    highlights.RexIsolation = { fg = '#abcdef' }
  end,
}
local original_options = vim.deepcopy(require('tokyonight.config').options)
local _, upstream = tokyonight.load()
local expected_tokyonight = {}
for name in pairs(upstream) do
  expected_tokyonight[name] = vim.api.nvim_get_hl(0, { name = name, link = false })
end
local changes = 0
vim.api.nvim_create_autocmd('ColorScheme', {
  pattern = 'rex',
  callback = function()
    changes = changes + 1
  end,
})
theme.setup { cache_file = cache_file, query_timeout = 20 }
vim.cmd.colorscheme 'rex'
assert(vim.o.termguicolors)
assert(not theme.refresh(), 'Headless instances must not query a terminal')
assert(#sent == 0)
highlight('Normal', '#c0caf5', '#1a1b26')
assert(vim.api.nvim_get_hl(0, { name = 'Comment' }).italic)

-- Ignore malformed/unrelated responses and never apply partial palettes.
tty = true
assert(theme.refresh())
assert(select(2, sent[#sent]:gsub('%?', '')) == 19)
receive '\027]4;0;rgb:12345/00/00'
receive '\027]4;999;rgb:ff/ff/ff'
receive '\027[?1;2c'
receive(response('4;0', '#123456'))
settle()
assert(theme.get_palette() == nil)
assert(changes == 1)

assert(theme.refresh())
reply(nil, '#35d0c0')
wait_for(function()
  return theme.get_palette() ~= nil
end)
assert(changes == 2)
local stored = vim.json.decode(table.concat(vim.fn.readfile(cache_file), '\n'))
assert(stored.version == 1 and vim.deep_equal(stored.palette, theme.get_palette()))
assert(vim.o.background == 'dark')
highlight('Normal', '#c2d8d8', '#0c1618')
highlight('Cursor', '#0c1618', '#35d0c0')
highlight('lCursor', '#0c1618', '#35d0c0')
highlight('TermCursor', '#0c1618', '#35d0c0')
highlight('CursorIM', '#0c1618', '#35d0c0')
highlight('Visual', '#c2d8d8', theme.get_palette().selection_background)
highlight('DiffAdd', nil, require('tokyonight.util').blend(ansi[3], 0.15, '#0c1618'))
highlight('PmenuSel', nil, Util.blend(Util.blend('#c2d8d8', 0.4, '#0c1618'), 0.8, '#0c1618'))
highlight('@string', ansi[3])
highlight('DiagnosticError', ansi[10])
highlight('GitSignsAdd', ansi[11])
for i, color in ipairs(ansi) do
  assert(vim.g['terminal_color_' .. (i - 1)] == color)
end
local cached = theme.get_palette()
cached.background = '#ffffff'
assert(theme.get_palette().background == '#0c1618', 'Palette getter must return a copy')

-- Identical palettes must not rebuild highlights or rewrite the cache.
local cache_inode = vim.uv.fs_stat(cache_file).ino
assert(theme.refresh())
reply(nil, '#35d0c0')
settle()
assert(changes == 2)
assert(vim.uv.fs_stat(cache_file).ino == cache_inode)

-- Handle short/uppercase channels, both terminators, and an absent cursor.
assert(theme.refresh())
reply()
receive '\027]4;1;rgb:F/0/8\007'
receive '\027]4;2;rgb:ABC/000/FFF\027\\'
settle()
assert(vim.g.terminal_color_1 == '#ff0088')
assert(vim.g.terminal_color_2 == '#ab00ff')
highlight('Cursor', '#0c1618', '#c2d8d8')

-- Missing responses preserve the last complete palette.
local before = theme.get_palette()
assert(theme.refresh())
receive(response('11', '#ffffff'))
settle()
assert(vim.deep_equal(theme.get_palette(), before))

-- A changed, light palette updates normally and emits ColorScheme again.
assert(theme.refresh())
reply('#f2f2f0', '#b3402e')
wait_for(function()
  return vim.o.background == 'light'
end)
highlight('Normal', '#c2d8d8', '#f2f2f0')
assert(vim.g.colors_name == 'rex' and vim.o.termguicolors)

-- Switching away cancels in-flight queries and restores upstream highlights.
assert(theme.refresh())
vim.cmd.colorscheme 'tokyonight-night'
reply(nil, '#35d0c0')
settle()
assert(vim.g.colors_name == 'tokyonight-night')
assert(not theme.refresh())
assert(vim.deep_equal(require('tokyonight.config').options, original_options), 'Rex changed TokyoNight configuration')
for name, expected in pairs(expected_tokyonight) do
  assert(vim.deep_equal(vim.api.nvim_get_hl(0, { name = name, link = false }), expected), 'Changed TokyoNight highlight: ' .. name)
end

-- A fresh module renders the disk cache before any terminal response.
local function restart(path)
  vim.cmd.colorscheme 'tokyonight-night'
  package.loaded['rex-theme'] = nil
  theme = require 'rex-theme'
  theme.setup { cache_file = path, query_timeout = 20 }
  vim.cmd.colorscheme 'rex'
end
local count = #sent
restart(cache_file)
highlight('Normal', '#c2d8d8', '#f2f2f0')
assert(theme.get_palette().background == '#f2f2f0')
assert(#sent == count, 'Cached colors must be applied synchronously')
wait_for(function()
  return #sent == count + 1
end)
settle()
assert(theme.get_palette().background == '#f2f2f0', 'Failed startup queries must retain the cache')
count = #sent
vim.wait(2100, function()
  return false
end, 5)
assert(#sent == count, 'Idle instances must not poll')

-- Focus and manual refresh still query, without reloading unchanged colors.
local before_changes = changes
vim.api.nvim_exec_autocmds('FocusGained', {})
wait_for(function()
  return #sent == count + 1
end)
reply('#f2f2f0', '#b3402e')
settle()
assert(changes == before_changes)
count = #sent
vim.cmd 'RexThemeRefresh'
assert(#sent == count + 1)
reply('#f2f2f0', '#b3402e')
settle()
assert(changes == before_changes)
vim.cmd.colorscheme 'tokyonight-night'
count = #sent
vim.api.nvim_exec_autocmds('FocusGained', {})
settle()
assert(#sent == count, 'Other themes must not query on focus')

-- Ignore broken, incompatible, or incomplete caches without throwing.
tty = false
local valid_cache = vim.fn.readfile(cache_file)
local invalid_palette = vim.deepcopy(stored.palette)
invalid_palette.terminal.blue = 'not-a-color'
for _, content in ipairs {
  '{broken-json',
  'null',
  vim.json.encode { version = 2, palette = stored.palette },
  vim.json.encode { version = 1, palette = {} },
  vim.json.encode { version = 1, palette = invalid_palette },
} do
  vim.fn.writefile({ content }, cache_file)
  restart(cache_file)
  assert(theme.get_palette() == nil)
  highlight('Normal', '#c0caf5', '#1a1b26')
end
vim.fn.writefile(valid_cache, cache_file)
restart(cache_file)
highlight('Normal', '#c2d8d8', '#f2f2f0')

-- Unwritable caches must not prevent a fresh palette from being applied.
local blocker = cache_directory .. '/not-a-directory'
vim.fn.writefile({ 'block directory creation' }, blocker)
tty = true
count = #sent
restart(blocker .. '/palette.json')
wait_for(function()
  return #sent == count + 1
end)
reply(nil, '#35d0c0')
wait_for(function()
  return theme.get_palette() ~= nil
end)
highlight('Normal', '#c2d8d8', '#0c1618')

-- Complete replies apply before the timeout, even with duplicate responses.
count = #sent
restart(false)
theme.setup { cache_file = false, query_timeout = 1000 }
wait_for(function()
  return #sent == count + 1
end)
local initial_changes = changes
vim.api.nvim_exec_autocmds({ 'VimEnter', 'UIEnter' }, { group = 'rex-theme' })
for _ = 1, 2 do
  for i, color in ipairs(ansi) do
    receive(response('4;' .. (i - 1), color))
  end
end
receive(response('10', '#c2d8d8'))
receive(response('12', '#35d0c0'))
-- A malformed duplicate must not erase an already valid color.
receive '\027]4;0;rgb:12345/00/00'
settle()
assert(theme.get_palette() == nil and changes == initial_changes, 'Duplicates must not complete a partial query')
receive(response('11', '#0c1618'))
assert(theme.get_palette() == nil, 'Do not render inside TermResponse')
wait_for(function()
  return theme.get_palette() ~= nil
end)
highlight('Normal', '#c2d8d8', '#0c1618')
assert(theme.get_palette().terminal.black == ansi[1])
settle()
assert(#sent == count + 1, 'Startup events must not queue redundant queries')

-- Cancel both a scheduled early completion and a pending focus refresh.
assert(theme.refresh())
reply('#ffffff', '#000000')
vim.api.nvim_exec_autocmds('FocusGained', {})
vim.cmd.colorscheme 'tokyonight-night'
settle()
assert(vim.g.colors_name == 'tokyonight-night')
assert(#sent == count + 2, 'Switching themes must cancel scheduled work')

-- A hidden pane may return only ANSI colors before it gains focus. Coalesce
-- focus/manual requests into one retry instead of dropping them or polling.
count = #sent
restart(false)
wait_for(function()
  return #sent == count + 1
end)
for i, color in ipairs(ansi) do
  receive(response('4;' .. (i - 1), color))
end
vim.api.nvim_exec_autocmds('FocusGained', {})
vim.api.nvim_exec_autocmds('FocusGained', {})
vim.cmd 'RexThemeRefresh'
vim.cmd 'RexThemeRefresh'
wait_for(function()
  return #sent == count + 2
end)
assert(theme.get_palette() == nil, 'Incomplete hidden-pane replies must not render')
reply(nil, '#35d0c0')
wait_for(function()
  return theme.get_palette() ~= nil
end)
settle()
assert(#sent == count + 2, 'Queued refreshes must coalesce into a single retry')
highlight('Normal', '#c2d8d8', '#0c1618')

-- Reconfiguring an active theme preserves the palette that was actually drawn,
-- even when the new cache already contains the terminal's next reply.
local replacement = theme.get_palette()
replacement.background = '#eeeeee'
replacement.foreground = '#202020'
replacement.cursor = '#303030'
replacement.cursor_text = replacement.background
replacement.selection_background = Util.blend(replacement.terminal.blue, 0.35, replacement.background)
replacement.selection_foreground = replacement.foreground
local replacement_cache = cache_directory .. '/replacement.json'
vim.fn.writefile({ vim.json.encode { version = 1, palette = replacement } }, replacement_cache)
before = theme.get_palette()
count = #sent
theme.setup { cache_file = replacement_cache, query_timeout = 20 }
assert(vim.deep_equal(theme.get_palette(), before), 'setup() must preserve the rendered palette')
highlight('Normal', '#c2d8d8', '#0c1618')
wait_for(function()
  return #sent == count + 1
end)
reply(replacement.background, replacement.cursor, replacement.foreground)
wait_for(function()
  return theme.get_palette().background == replacement.background
end)
assert(vim.deep_equal(theme.get_palette(), replacement))
highlight('Normal', replacement.foreground, replacement.background)

-- Disabling caching or passing invalid options must not discard active colors.
tty = false
count = #sent
theme.setup { cache_file = false, query_timeout = 20 }
settle()
assert(#sent == count and vim.deep_equal(theme.get_palette(), replacement))
for _, timeout in ipairs { -1, 0, 0.5, math.huge, '20' } do
  assert(not pcall(theme.setup, { cache_file = false, query_timeout = timeout }))
end
local original_has = vim.fn.has
vim.fn.has = function(feature)
  return feature == 'nvim-0.12' and 0 or original_has(feature)
end
local supported, version_error = pcall(theme.setup, { cache_file = false })
vim.fn.has = original_has
assert(not supported and version_error:find('requires Neovim 0.12', 1, true))
assert(vim.deep_equal(theme.get_palette(), replacement))
highlight('Normal', replacement.foreground, replacement.background)

-- Conventional ANSI white/black must not become neutral UI text/backgrounds.
-- Check the same ANSI palette against both light and dark terminal backgrounds.
local conventional_ansi = {
  '#000000',
  '#cd0000',
  '#00cd00',
  '#cdcd00',
  '#0000ee',
  '#cd00cd',
  '#00cdcd',
  '#e5e5e5',
  '#7f7f7f',
  '#ff0000',
  '#00ff00',
  '#ffff00',
  '#5c5cff',
  '#ff00ff',
  '#00ffff',
  '#ffffff',
}
tty = true
for _, pair in ipairs { { '#f2f2f0', '#202020' }, { '#121212', '#eeeeee' } } do
  assert(theme.refresh())
  reply(pair[1], pair[2], pair[2], conventional_ansi)
  wait_for(function()
    return theme.get_palette().background == pair[1]
  end)
  highlight('Normal', pair[2], pair[1])
  for _, name in ipairs {
    'Normal',
    'NormalFloat',
    'NormalSB',
    'CursorLine',
    'MsgArea',
    'ModeMsg',
    'StatusLine',
    'WinBar',
    'Pmenu',
    'PmenuSel',
    'Search',
    'Comment',
  } do
    contrast(name)
  end
  for i, color in ipairs(conventional_ansi) do
    assert(vim.g['terminal_color_' .. (i - 1)] == color, 'ANSI terminal colors must remain unchanged')
  end
end

-- Switching away also discards a retry queued during an incomplete query.
count = #sent
assert(theme.refresh())
assert(not theme.refresh())
vim.cmd.colorscheme 'tokyonight-night'
settle()
assert(#sent == count + 1, 'Canceled queries must not retry')
vim.fn.delete(cache_directory, 'rf')

Util.cache.file = original_cache_file
vim.api.nvim_ui_send, vim.api.nvim_list_uis = original_send, original_uis
print 'rex-theme: all tests passed'
