local root = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h:h')
vim.opt.runtimepath:prepend(root)
vim.cmd.packadd 'lush.nvim'
vim.cmd.packadd 'zenbones.nvim'

local original_system, original_has = vim.system, vim.fn.has
local requests, calls = {}, 0
local mac = true
vim.fn.has = function(feature)
  if feature == 'mac' then
    return mac and 1 or 0
  end
  return original_has(feature)
end
vim.system = function(command, opts, callback)
  assert(command[1] == '/usr/bin/defaults' and command[2] == 'read', 'Only preference reads are allowed')
  assert(opts.text and opts.timeout == 1000, 'Reads must be asynchronous and bounded')
  calls = calls + 1
  local request = { command = command, callback = callback }
  requests[#requests + 1] = request
  return {
    kill = function(_, signal)
      assert(signal == 15)
      request.killed = true
    end,
  }
end

local function equal(actual, expected, label)
  assert(vim.deep_equal(actual, expected), label .. ': expected ' .. vim.inspect(expected) .. ', got ' .. vim.inspect(actual))
end

local function settle()
  vim.wait(20, function()
    return false
  end, 1)
end

local function answer(key, value, domain, code)
  assert(
    vim.wait(500, function()
      return #requests > 0
    end, 1),
    'Missing preference read: ' .. key
  )
  local request = table.remove(requests, 1)
  equal(request.command[3], domain or 'com.superlogical.rex', 'Preference domain')
  equal(request.command[4], key, 'Preference key')
  request.callback { code = code or (value and 0 or 1), stdout = value and (value .. '\n') or '', stderr = '' }
  settle()
  return request
end

local function event(name)
  vim.api.nvim_exec_autocmds(name, {})
end

local function run()
  local theme = require 'rexbones'
  vim.cmd.colorscheme 'petrolbones'
  theme.setup()
  settle()
  equal(package.loaded['rexbones.sync'], nil, 'Tracking module is opt-in')
  equal(calls, 0, 'Standalone loading spawns no processes')

  local changes = 0
  vim.api.nvim_create_autocmd('ColorScheme', {
    callback = function()
      changes = changes + 1
    end,
  })

  theme.setup { auto_sync = true }
  settle()
  event 'VimEnter'
  event 'UIEnter'
  event 'FocusGained'
  equal(calls, 1, 'Overlapping refreshes share one query')
  answer('Workspace.appearance', 'dark')
  answer('Workspace.darkThemeID', 'petrol-lagoon')
  equal(changes, 0, 'Unchanged startup theme does not reload')
  local idle_calls = calls
  settle()
  equal(calls, idle_calls, 'No idle polling')

  -- Every bundled Rex ID selects its named colorscheme and appearance.
  for name, variants in pairs(require 'rexbones.themes') do
    for background, id in pairs(variants) do
      event 'FocusGained'
      answer('Workspace.appearance', background)
      answer('Workspace.' .. background .. 'ThemeID', id)
      equal(vim.g.colors_name, name, id .. ' colorscheme')
      equal(vim.o.background, background, id .. ' appearance')
    end
  end

  for _, case in ipairs {
    { style = 'Dark', id = 'merino-dark', background = 'dark' },
    { id = 'merino-light', background = 'light' },
  } do
    event 'FocusGained'
    answer('Workspace.appearance', 'auto')
    answer('AppleInterfaceStyle', case.style, '-g')
    answer('Workspace.' .. case.background .. 'ThemeID', case.id)
    equal(vim.g.colors_name, 'merinobones', 'Auto appearance colorscheme')
    equal(vim.o.background, case.background, 'Auto appearance variant')
  end

  local before = changes
  event 'FocusGained'
  answer('Workspace.appearance', 'light')
  answer('Workspace.lightThemeID', 'merino-light')
  equal(changes, before, 'Unchanged dual-appearance theme does not reload')
  event 'FocusGained'
  answer('Workspace.appearance', nil)
  equal(#requests, 0, 'Missing Rex preferences stop the query')
  event 'FocusGained'
  answer('Workspace.appearance', 'dark')
  answer('Workspace.darkThemeID', nil)
  event 'FocusGained'
  answer('Workspace.appearance', 'dark')
  answer('Workspace.darkThemeID', 'unbundled-theme')
  equal(changes, before, 'Failed reads and unknown IDs preserve highlights')
  equal(vim.o.background, 'light', 'Unknown ID preserves background')

  event 'FocusGained'
  answer('Workspace.appearance', nil, nil, 124)
  equal(#requests, 0, 'Appearance timeout stops the query')
  event 'FocusGained'
  answer('Workspace.appearance', 'auto')
  answer('AppleInterfaceStyle', nil, '-g', 124)
  equal(#requests, 0, 'System appearance timeout does not assume light mode')
  event 'FocusGained'
  answer('Workspace.appearance', 'dark')
  answer('Workspace.darkThemeID', nil, nil, 124)
  equal(changes, before, 'Timeouts preserve highlights')

  event 'FocusGained'
  answer('Workspace.appearance', 'dark')
  local stale = requests[1]
  vim.cmd.colorscheme 'basaltbones'
  assert(stale.killed, 'Manual colorscheme selection cancels pending reads')
  answer('Workspace.darkThemeID', 'petrol-lagoon')
  equal(vim.g.colors_name, 'basaltbones', 'Late reply cannot override manual selection')
  idle_calls = calls
  event 'FocusGained'
  equal(calls, idle_calls, 'Manual selection stops tracking')

  theme.setup { auto_sync = true }
  settle()
  stale = requests[1]
  theme.setup { auto_sync = false }
  assert(stale.killed, 'Disabling cancels pending reads')
  answer('Workspace.appearance', 'light')
  equal(#requests, 0, 'Disabled query cannot issue more reads')
  event 'FocusGained'
  equal(vim.g.colors_name, 'basaltbones', 'Disabling preserves current theme')

  theme.setup { auto_sync = true }
  settle()
  stale = requests[1]
  theme.setup { auto_sync = true }
  assert(stale.killed, 'Repeated setup cancels the previous query')
  answer('Workspace.appearance', 'light')
  answer('Workspace.appearance', 'dark')
  answer('Workspace.darkThemeID', 'petrol-lagoon')
  equal(vim.g.colors_name, 'petrolbones', 'Repeated setup accepts only fresh replies')

  event 'FocusGained'
  stale = requests[1]
  event 'VimLeavePre'
  assert(stale.killed, 'Exit cancels pending reads')
  answer('Workspace.appearance', 'light')
  equal(#requests, 0, 'Exit discards late callbacks')

  idle_calls = calls
  theme.setup { auto_sync = true }
  theme.setup { auto_sync = false }
  settle()
  equal(calls, idle_calls, 'Disabling before scheduled startup spawns no processes')

  mac = false
  idle_calls = calls
  theme.setup { auto_sync = true }
  settle()
  event 'FocusGained'
  equal(calls, idle_calls, 'Unsupported platforms spawn no processes')
  theme.setup { auto_sync = false }
  print 'PASS: opt-in tracking, all 41 Rex IDs, auto appearance, async reads, no polling, deduplication, failures, and cancellation'
end

local ok, err = xpcall(run, debug.traceback)
vim.system, vim.fn.has = original_system, original_has
if not ok then
  io.stderr:write(err .. '\n')
  vim.cmd 'cquit 1'
end
