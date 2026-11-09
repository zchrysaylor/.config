local home = assert(os.getenv("HOME"), "HOME must be set")
local roots = {
  home .. "/Code",
  home .. "/Code/IdeaProjects/deliveryhero",
  home .. "/forge",
  home .. "/Documents/geumgo",
}

local function checked(result, err)
  if result == nil then error(err, 0) end
  return result
end

local function executable(name)
  local directories = {
    "/opt/homebrew/bin",
    "/usr/local/bin",
    home .. "/.local/bin",
  }
  if name == "rex" then
    table.insert(directories, 1, home .. "/Library/Application Support/com.superlogical.rex/RexServer/Versions/Current/Rex Server.app/Contents/MacOS")
    if os.getenv("REX_BIN_DIR") then
      table.insert(directories, 1, os.getenv("REX_BIN_DIR"))
    end
  end
  for directory in (os.getenv("PATH") or ""):gmatch("[^:]+") do
    directories[#directories + 1] = directory
  end
  for _, directory in ipairs(directories) do
    local path = directory .. "/" .. name
    if checked(rex.exec({ "/bin/test", "-x", path })).ok then return path end
  end
  error("Sessionizer requires " .. name .. " on PATH or in a standard installation directory", 0)
end

local function pick()
  local fd = executable("fd")
  local sk = executable("sk")
  local paths = {}
  local function add(path)
    path = path:gsub("/+$", "")
    local display = path
    if path:sub(1, #home + 1) == home .. "/" then display = path:sub(#home + 2) end
    paths[display] = path
  end

  -- Preserve the Herdr picker's one-level directory search, including non-Git directories.
  local command = { fd, "--type=directory", "--max-depth=1", "--full-path", "--print0", "--color=never", "." }
  for _, root in ipairs(roots) do
    if checked(rex.exec({ "/bin/test", "-d", root })).ok then
      command[#command + 1] = root
      if root == home .. "/Code" or root == home .. "/forge" then add(root) end
    end
  end
  if #command == 7 then error("None of the sessionizer's search roots exist", 0) end

  local found = checked(rex.exec(command))
  if not found.ok then error("Project discovery failed: " .. found.stderr, 0) end
  for path in found.stdout:gmatch("([^%z]+)%z") do add(path) end

  local entries = {}
  for display in pairs(paths) do entries[#entries + 1] = display end
  table.sort(entries)
  if #entries == 0 then error("No project directories found", 0) end

  -- Run in the popup's CLI process, not a config action's 30-second lifetime.
  -- sk reads keys from /dev/tty; forward its stderr so its UI reaches the popup.
  local picker = checked(rex.exec.start({ sk, "--read0", "--print0", "--no-multi", "--margin=10%" }, {
    stdin = table.concat(entries, "\0") .. "\0",
    stderr = function(data) io.write(data) end,
  }))
  local selected = checked(picker:wait())
  if selected.code == 1 or selected.code == 130 then return end
  if not selected.ok then error("sk exited with status " .. selected.code, 0) end
  local display = selected.stdout:match("^([^%z]+)%z$")
  local cwd = display and paths[display]
  if cwd == nil then error("sk returned an invalid project selection", 0) end

  local opened = checked(rex.invoke("open_project_session", { cwd = cwd, focus = false }))
  -- In a CLI script this is synchronous, so a refused switch is reported here.
  rex.client.queue("session.select", { session_id = opened.session_id, window_id = opened.window_id })
  return opened
end

local function app_client(ctx)
  local apps = {}
  local listed = checked(rex.call("client.list"))
  for _, client in ipairs(listed.clients or {}) do
    if client.info and client.info.kind == "app" and client.connection_state == "connected" then
      if client.client_id == ctx.client_id then return client.client_id end
      apps[#apps + 1] = client.client_id
    end
  end
  if #apps ~= 1 then error("Open the project picker with its keybinding in the intended Rex app", 0) end
  return apps[1]
end

local function setup(script_path)
  rex.action{
    name = "pick_project_session",
    title = "Pick Project Session",
    category = "Session",
    run = function(ctx)
      assert(ctx.session_id, "Open the project picker from an existing Rex session")
      local client_id = app_client(ctx)
      local view = checked(rex.session.view{ session_id = ctx.session_id })
      return checked(rex.session.new_layer{
        session_id = ctx.session_id,
        window_id = view.active_window_id,
        bounds = { 0.2, 0.1, 0.6, 0.8 },
        focus = true,
        layout = {
          block = {
            flavor = "com.superlogical.terminal.shell",
            options = {
              cwd = home,
              shell = "none",
              login = false,
              command = {
                executable("rex"), "--autostart=false", "-C", client_id,
                "do", script_path, "--session", ctx.session_id, "pick=true",
              },
            },
          },
        },
      })
    end,
  }
  rex.bind("ctrl+b>f", "pick_project_session")
end

if rex.args and rex.args.pick then
  local ok, result = pcall(pick)
  if not ok then
    io.write("\n" .. tostring(result) .. "\nPress Enter to close.\n")
    io.read("*l")
    rex.stop(1)
  end
  return result
end
return { setup = setup, pick = pick }
