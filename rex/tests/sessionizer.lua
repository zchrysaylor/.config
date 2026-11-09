-- Run from ~/.config: lua rex/tests/sessionizer.lua
local home = assert(os.getenv("HOME"))
local config = os.getenv("XDG_CONFIG_HOME") or (home .. "/.config")
local actions, bindings = {}, {}
local state
local function reset()
  state = {
    sessions = {}, queued = {}, directories = true,
    clients = { { client_id = "app", info = { kind = "app" }, connection_state = "connected" } },
    discovered = home .. "/Code/repo.one/\0" .. home .. "/Code/repo.one/\0"
      .. home .. "/Code/space ' ; $ repo/\0",
    selection = "Code/repo.one\0", picker_code = 0,
  }
end
reset()

rex = {
  args = {},
  action = function(action) actions[action.name] = action end,
  bind = function(key, action, args) bindings[key] = { action = action, args = args } end,
  exec = {},
  invoke = function(name, args)
    state.invoked = { name = name, args = args }
    return { session_id = "selected" }
  end,
  call = function(method, args)
    if method == "client.list" then return { clients = state.clients } end
    if method == "session.list" then return { sessions = state.sessions } end
    assert(method == "session.create")
    state.created = args
    return { session_id = "new", initial_windows = { { window_id = "pi" }, { window_id = "shell" } } }
  end,
  client = { queue = function(name, args)
    if state.client_error then error(state.client_error, 0) end
    state.queued[#state.queued + 1] = { name = name, args = args }
  end },
  session = {
    view = function() return { active_window_id = "origin-tab", label = state.session_label or "repo_one" } end,
    new_layer = function(args) state.layer = args; return { layer_id = "popup" } end,
    new_window = function(args) state.window = args; return { window_id = "extra" } end,
  },
}
rex.exec = setmetatable({}, {
  __call = function(_, ...) return rex.run_exec(...) end,
})
-- Lua tables model Rex's callable rex.exec with its .start member.
rex.run_exec = function(argv)
  if argv[1] == "/bin/test" then
    local ok = argv[2] == "-x" or state.directories
    return { ok = ok, code = ok and 0 or 1 }
  end
  assert(argv[1]:match("/fd$"), "Unexpected executable")
  assert(argv[5] == "--print0")
  state.discovery_command = argv
  return { ok = not state.discovery_error, stdout = state.discovered, stderr = "discovery error" }
end
rex.exec.start = function(argv, options)
  assert(argv[1]:match("/sk$"))
  assert(argv[2] == "--read0" and argv[3] == "--print0" and argv[4] == "--no-multi")
  assert(type(options.stderr) == "function")
  state.picker_input = options.stdin
  return { wait = function()
    return { ok = state.picker_code == 0, code = state.picker_code, stdout = state.selection }
  end }
end

dofile(config .. "/rex/init.lua")
local picker = dofile(config .. "/rex/sessionizer.lua")
local tests = 0
local function test(name, fn)
  reset()
  fn()
  tests = tests + 1
  print("ok - " .. name)
end
local function fails(fn, expected)
  local ok, err = pcall(fn)
  assert(not ok and tostring(err):find(expected, 1, true), tostring(err))
end

test("prefix+f opens an origin-scoped native float without a login shell", function()
  assert(bindings["ctrl+b>f"].action == "pick_project_session")
  actions.pick_project_session.run({ session_id = "origin", client_id = "app" })
  assert(state.layer.session_id == "origin" and state.layer.window_id == "origin-tab")
  assert(state.layer.bounds[1] == 0.2 and state.layer.bounds[3] == 0.6 and state.layer.bounds[4] == 0.8)
  local options = state.layer.layout.block.options
  assert(options.shell == "none" and options.login == false)
  assert(table.concat(options.command, " "):find("-C app do " .. config .. "/rex/sessionizer.lua", 1, true))
end)

test("CLI invocation resolves the app instead of passing its transient CLI client", function()
  actions.pick_project_session.run({ session_id = "origin", client_id = "transient-cli" })
  assert(state.layer.layout.block.options.command[4] == "app")
end)

test("multiple apps require the initiating app's identity", function()
  state.clients[#state.clients + 1] = { client_id = "other-app", info = { kind = "app" }, connection_state = "connected" }
  fails(function() actions.pick_project_session.run({ session_id = "origin", client_id = "transient-cli" }) end,
    "intended Rex app")
  actions.pick_project_session.run({ session_id = "origin", client_id = "other-app" })
  assert(state.layer.layout.block.options.command[4] == "other-app")
end)

test("discovery deduplicates paths and shows home-relative entries", function()
  picker.pick()
  assert(state.picker_input == "Code\0Code/repo.one\0Code/space ' ; $ repo\0forge\0")
  assert(state.invoked.name == "open_project_session")
  assert(state.invoked.args.cwd == home .. "/Code/repo.one" and state.invoked.args.focus == false)
  assert(state.queued[1].name == "session.select" and state.queued[1].args.session_id == "selected")
end)

test("unusual paths are passed as data, without shell interpolation", function()
  state.discovered = home .. "/Code/space ' ; $ repo/\0" .. home .. "/Code/multi\nline/\0"
  state.selection = "Code/multi\nline\0"
  picker.pick()
  assert(state.invoked.args.cwd == home .. "/Code/multi\nline")
end)

for _, code in ipairs({ 1, 130 }) do
  test("cancellation/no match does not open a session (" .. code .. ")", function()
    state.picker_code = code
    picker.pick()
    assert(state.invoked == nil)
  end)
end

test("discovery, picker, and invalid-selection errors are not swallowed", function()
  state.discovery_error = true
  fails(picker.pick, "Project discovery failed")
  state.discovery_error = false
  state.picker_code = 2
  fails(picker.pick, "sk exited with status 2")
  state.picker_code = 0
  state.selection = "not a discovered path\0"
  fails(picker.pick, "invalid project selection")
end)

test("client refusal is reported instead of silently dropping a session switch", function()
  state.client_error = "Turn on Remote Control"
  fails(picker.pick, "Turn on Remote Control")
end)

test("missing roots do not make fd search its current directory", function()
  state.directories = false
  fails(picker.pick, "None of the sessionizer's search roots exist")
  assert(state.discovery_command == nil)
end)

test("new projects get only Pi and shell tabs, with automatic tab names", function()
  local result = actions.open_project_session.run({}, { cwd = home .. "/Code/repo.one" })
  assert(result.created and state.created.label == "repo_one")
  assert(#state.created.initial_windows == 2)
  for _, window in ipairs(state.created.initial_windows) do
    assert(window.window_label == nil and window.layout.block.label == nil)
    assert(window.layout.block.options.cwd == home .. "/Code/repo.one")
  end
  assert(state.created.initial_windows[1].layout.block.options.initial_input == "pi\n")
  assert(state.created.initial_windows[2].layout.block.options.initial_input == nil)
  assert(state.queued[1].args.window_id == "shell")
end)

test("CLI selection can create without queuing an asynchronous app action", function()
  local result = actions.open_project_session.run({}, { cwd = home .. "/Code/repo.one", focus = false })
  assert(result.window_id == "shell" and #state.queued == 0)
end)

test("the picker preserves shortcut labels and reuses their sessions", function()
  state.sessions = { { label = ".config", session_id = "config" } }
  local result = actions.open_project_session.run({}, { cwd = home .. "/.config" })
  assert(not result.created and result.session_id == "config")
  assert(state.created == nil and state.queued[1].args.session_id == "config")
end)

test("fixed shortcuts still use the shared unnamed-tab session action", function()
  local binding = bindings["ctrl+b>shift+o"]
  assert(binding.action == "open_project_session")
  actions.open_project_session.run({}, binding.args)
  assert(state.created.label == "otv2")
  for _, window in ipairs(state.created.initial_windows) do assert(window.window_label == nil) end
end)

test("new-tab bindings use a picked project's root and automatic tab naming", function()
  local root = home .. "/Code/dynamically-picked"
  actions.open_project_session.run({}, { cwd = root })
  actions.new_project_tab.run({ session_id = "new" })
  assert(bindings["cmd+t"].action == "new_project_tab")
  assert(bindings["ctrl+b>c"].action == "new_project_tab")
  assert(state.window.window_label == nil and state.window.layout.block.options.cwd == root)
end)

test("invalid project directories are rejected before creation", function()
  state.directories = false
  fails(function() actions.open_project_session.run({}, { cwd = "/does-not-exist" }) end, "Directory does not exist")
  assert(state.created == nil)
end)

print(tests .. " tests passed")
