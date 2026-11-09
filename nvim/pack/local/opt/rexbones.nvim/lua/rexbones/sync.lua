local M = {}
local domain = 'com.superlogical.rex'
local group, pending
local enabled, applying = false, false
local themes = {}

for name, variants in pairs(require 'rexbones.themes') do
  for background, id in pairs(variants) do
    themes[id] = { name = name, background = background }
  end
end

local function stop()
  enabled = false
  if pending and pending.process then
    pending.process:kill(15)
  end
  pending = nil
  if group then
    vim.api.nvim_clear_autocmds { group = group }
  end
end

local function refresh()
  if not enabled or pending then
    return
  end
  local query = {}
  pending = query

  local function read(preferences, key, callback)
    query.process = vim.system({ '/usr/bin/defaults', 'read', preferences, key }, { text = true, timeout = 1000 }, function(result)
      vim.schedule(function()
        if pending == query then
          callback(result.code == 0 and vim.trim(result.stdout) or nil, result.code)
        end
      end)
    end)
  end

  local function load(background)
    read(domain, 'Workspace.' .. background .. 'ThemeID', function(id)
      pending = nil
      local theme = themes[id]
      if not theme or (vim.g.colors_name == theme.name and vim.o.background == theme.background) then
        return
      end
      applying = true
      local ok, err = pcall(function()
        vim.o.background = theme.background
        vim.cmd.colorscheme(theme.name)
      end)
      applying = false
      if not ok then
        vim.notify('rexbones: ' .. tostring(err), vim.log.levels.ERROR)
      end
    end)
  end

  read(domain, 'Workspace.appearance', function(appearance)
    if appearance == 'dark' or appearance == 'light' then
      load(appearance)
    elseif appearance then
      -- Auto follows macOS. AppleInterfaceStyle is absent in light mode.
      read('-g', 'AppleInterfaceStyle', function(style, code)
        if code == 0 or code == 1 then
          load(style == 'Dark' and 'dark' or 'light')
        else
          pending = nil
        end
      end)
    else
      pending = nil
    end
  end)
end

function M.setup(auto_sync)
  stop()
  if not auto_sync or vim.fn.has 'mac' ~= 1 then
    return
  end
  enabled = true
  group = vim.api.nvim_create_augroup('rexbones-sync', { clear = true })
  vim.api.nvim_create_autocmd({ 'VimEnter', 'UIEnter', 'FocusGained' }, {
    group = group,
    callback = refresh,
  })
  vim.api.nvim_create_autocmd('ColorSchemePre', {
    group = group,
    callback = function()
      if not applying then
        stop()
      end
    end,
  })
  vim.api.nvim_create_autocmd('VimLeavePre', { group = group, callback = stop })
  vim.schedule(refresh)
end

return M
