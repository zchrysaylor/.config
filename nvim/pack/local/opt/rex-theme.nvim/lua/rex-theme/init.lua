local M = {}

local terminal_names = {
  'black',
  'red',
  'green',
  'yellow',
  'blue',
  'magenta',
  'cyan',
  'white',
  'black_bright',
  'red_bright',
  'green_bright',
  'yellow_bright',
  'blue_bright',
  'magenta_bright',
  'cyan_bright',
  'white_bright',
}
local options
local configured, active = false, false
local palette, pending, timeout_timer
local refresh_queued = false

local function refresh_if_idle()
  if not pending then
    M.refresh()
  end
end

local function default_cache_file()
  local terminal = (vim.env.TERM_PROGRAM or 'unknown') .. ':' .. (vim.env.TERM or 'unknown')
  return vim.fn.stdpath 'cache' .. '/rex-theme/' .. vim.fn.sha256(terminal):sub(1, 16) .. '.json'
end

local function read_cache()
  if not options.cache_file then
    return nil
  end
  local ok, stored = pcall(function()
    return vim.json.decode(table.concat(vim.fn.readfile(options.cache_file), '\n'))
  end)
  if not ok or type(stored) ~= 'table' or stored.version ~= 1 or type(stored.palette) ~= 'table' then
    return nil
  end
  local cached = stored.palette
  local function is_color(value)
    return type(value) == 'string' and value:match '^#%x%x%x%x%x%x$' ~= nil
  end
  for _, name in ipairs { 'background', 'foreground', 'cursor', 'cursor_text', 'selection_background', 'selection_foreground' } do
    if not is_color(cached[name]) then
      return nil
    end
  end
  if type(cached.terminal) ~= 'table' then
    return nil
  end
  for _, name in ipairs(terminal_names) do
    if not is_color(cached.terminal[name]) then
      return nil
    end
  end
  return cached
end

local function write_cache()
  if not options.cache_file then
    return
  end
  local temporary = options.cache_file .. '.' .. vim.uv.os_getpid() .. '.tmp'
  local ok = pcall(function()
    vim.fn.mkdir(vim.fn.fnamemodify(options.cache_file, ':h'), 'p')
    local stored = vim.json.encode { version = 1, palette = palette }
    assert(vim.fn.writefile({ stored }, temporary) == 0)
    assert(vim.uv.fs_rename(temporary, options.cache_file))
  end)
  if not ok then
    -- Caching is best-effort; unwritable cache directories must not break colors.
    pcall(vim.fn.delete, temporary)
  end
end

local function close_timer(timer)
  if timer and not timer:is_closing() then
    timer:stop()
    timer:close()
  end
end

local function stop()
  active = false
  pending, refresh_queued = nil, false
  close_timer(timeout_timer)
  timeout_timer = nil
end

local function rgb(red, green, blue)
  local channels = {}
  for _, channel in ipairs { red, green, blue } do
    if #channel > 4 then
      return nil
    end
    local value = math.floor(tonumber(channel, 16) * 255 / (16 ^ #channel - 1) + 0.5)
    channels[#channels + 1] = ('%02x'):format(value)
  end
  return '#' .. table.concat(channels)
end

local function finish_query(query)
  if pending ~= query then
    return
  end
  pending = nil
  close_timer(timeout_timer)
  timeout_timer = nil
  if refresh_queued then
    refresh_queued = false
    vim.schedule(refresh_if_idle)
  end
  local reply = query.palette
  if not active or vim.g.colors_name ~= 'rex' or not reply.foreground or not reply.background then
    return
  end
  for _, name in ipairs(terminal_names) do
    if not reply.terminal[name] then
      -- Hidden Rex panes can report a fallback ANSI palette without the
      -- foreground/background. Only apply a complete palette, atomically.
      return
    end
  end
  local Util = require 'tokyonight.util'
  reply.cursor = reply.cursor or reply.foreground
  reply.cursor_text = reply.background
  reply.selection_background = Util.blend(reply.terminal.blue, 0.35, reply.background)
  reply.selection_foreground = reply.foreground
  if not vim.deep_equal(palette, reply) then
    palette = reply
    write_cache()
    -- Emit a normal ColorScheme event so plugins can restore their highlights.
    vim.cmd.colorscheme 'rex'
  end
end

local function receive(sequence)
  local query = pending
  if not query then
    return
  end
  -- Neovim normally strips the terminator; accept terminated replies too.
  sequence = sequence:gsub('\027\\$', ''):gsub('\007$', '')
  local index, r, g, b = sequence:match '^\027%]4;(%d+);rgb:(%x+)/(%x+)/(%x+)$'
  local target, name
  if index then
    target, name = query.palette.terminal, terminal_names[tonumber(index) + 1]
  else
    local code
    code, r, g, b = sequence:match '^\027%](%d+);rgb:(%x+)/(%x+)/(%x+)$'
    target = query.palette
    name = ({ ['10'] = 'foreground', ['11'] = 'background', ['12'] = 'cursor' })[code]
  end
  if not name then
    return
  end
  local color = rgb(r, g, b)
  if not color then
    return
  end
  if not target[name] then
    query.remaining = query.remaining - 1
  end
  target[name] = color
  if query.remaining == 0 and not query.complete then
    query.complete = true
    -- TermResponse can interrupt other events. Apply highlights on the next turn.
    vim.schedule(function()
      finish_query(query)
    end)
  end
end

function M.refresh()
  if not active or vim.g.colors_name ~= 'rex' then
    return false
  end
  if pending then
    refresh_queued = true
    return false
  end
  local has_tty = false
  for _, ui in ipairs(vim.api.nvim_list_uis()) do
    has_tty = has_tty or ui.stdout_tty == true
  end
  if not has_tty then
    return false
  end
  local query = { palette = { terminal = {} }, remaining = 19 }
  pending = query
  timeout_timer = vim.defer_fn(function()
    finish_query(query)
  end, options.query_timeout)
  local queries = {}
  for index = 0, 15 do
    queries[#queries + 1] = ('\027]4;%d;?\027\\'):format(index)
  end
  for _, code in ipairs { 10, 11, 12 } do
    queries[#queries + 1] = ('\027]%d;?\027\\'):format(code)
  end
  vim.api.nvim_ui_send(table.concat(queries))
  return true
end

function M.setup(opts)
  assert(vim.fn.has 'nvim-0.12' == 1 and type(vim.api.nvim_ui_send) == 'function', 'rex-theme requires Neovim 0.12 or newer')
  local next_options = vim.tbl_extend('force', { query_timeout = 800 }, opts or {})
  if next_options.cache_file == nil then
    next_options.cache_file = default_cache_file()
  end
  assert(
    type(next_options.query_timeout) == 'number' and next_options.query_timeout > 0 and next_options.query_timeout % 1 == 0,
    'query_timeout must be a positive integer in milliseconds'
  )
  assert(next_options.cache_file == false or type(next_options.cache_file) == 'string', 'cache_file must be a path or false')
  options = next_options
  close_timer(timeout_timer)
  timeout_timer, pending, refresh_queued = nil, nil, false
  -- Keep the palette paired with the currently rendered highlights. A new cache
  -- path must not suppress an update just because its contents match a reply.
  if not active then
    palette = read_cache()
  end
  local group = vim.api.nvim_create_augroup('rex-theme', { clear = true })
  vim.api.nvim_create_autocmd('TermResponse', {
    group = group,
    callback = function(event)
      receive(event.data.sequence)
    end,
  })
  vim.api.nvim_create_autocmd({ 'VimEnter', 'UIEnter' }, {
    group = group,
    callback = function()
      vim.schedule(refresh_if_idle)
    end,
  })
  vim.api.nvim_create_autocmd('FocusGained', {
    group = group,
    callback = function()
      vim.schedule(M.refresh)
    end,
  })
  vim.api.nvim_create_autocmd('ColorSchemePre', {
    group = group,
    callback = function(event)
      if event.match ~= 'rex' then
        stop()
      end
    end,
  })
  vim.api.nvim_create_autocmd('VimLeavePre', { group = group, callback = stop })
  vim.api.nvim_create_user_command('RexThemeRefresh', function()
    M.refresh()
  end, { desc = 'Re-query the terminal color palette', force = true })
  configured = true
  if active then
    vim.schedule(refresh_if_idle)
  end
end

function M.activate()
  if not configured then
    M.setup()
  end
  local was_active = active
  active = true
  -- Render the cached palette immediately; TokyoNight is the first-run fallback.
  require('rex-theme.renderer').apply(palette)
  if not was_active then
    vim.schedule(refresh_if_idle)
  end
end

function M.get_palette()
  return palette and vim.deepcopy(palette) or nil
end

return M
