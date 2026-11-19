--- Project sessions and the floating project picker for Rex.
local tyrannosession_rex = {}
local home = assert(os.getenv("HOME"), "HOME must be set")
local config
local records

--- Return a Rex result, raising an error if the call failed.
local function fossilize(result, err)
   if result == nil then
      error(err or "Rex returned no result", 0)
   end
   return result
end

--- Normalize absolute paths without resolving symlinks.
local function absolute(path)
   assert(type(path) == "string" and path ~= "" and not path:find("%c"), "Expected a path without control characters")
   if path == "~" then
      path = home
   elseif path:sub(1, 2) == "~/" then
      path = home .. path:sub(2)
   end
   assert(path:sub(1, 1) == "/", "Path must be absolute: " .. path)
   local parts = {}
   for part in path:gmatch("[^/]+") do
      if part == ".." then
         table.remove(parts)
      elseif part ~= "." then
         parts[#parts + 1] = part
      end
   end
   return "/" .. table.concat(parts, "/")
end

--- Missing state is normal; unreadable or malformed state must not be overwritten.
local function load_records()
   if records then
      return
   end
   local file, err, code = io.open(config.state_path, "r")
   if not file then
      -- Rex's Lua reports generic code 1 for OS errors instead of POSIX ENOENT.
      local missing = code == 2 or tostring(err):match("no such file or directory$")
      assert(missing, "Cannot read project-session state: " .. tostring(err))
      records = {}
      return
   end
   local contents = assert(file:read("*a"))
   assert(file:close())
   local saved = fossilize(rex.json.decode(contents))
   assert(type(saved) == "table" and saved.version == 1 and type(saved.sessions) == "table", "Invalid project-session state: " .. config.state_path)
   records = saved.sessions
end

--- Write beside the destination, then atomically replace it. Never evaluate state as Lua.
local function save_records()
   local parent = config.state_path:match("^(.*)/[^/]+$")
   local made = fossilize(rex.exec({ "/bin/mkdir", "-p", parent == "" and "/" or parent }))
   assert(made.ok, "Cannot create project-session state directory: " .. made.stderr)
   local encoded = fossilize(rex.json.encode({ version = 1, sessions = records }))
   local token = os.tmpname()
   os.remove(token)
   local temporary = config.state_path .. "." .. token:match("[^/]+$") .. ".tmp"
   local ok, err = pcall(function()
      local file = assert(io.open(temporary, "w"))
      local written, write_err = file:write(encoded .. "\n")
      local closed, close_err = file:close()
      assert(written, write_err)
      assert(closed, close_err)
      assert(os.rename(temporary, config.state_path))
   end)
   if not ok then
      os.remove(temporary)
      error(err, 0)
   end
end

local function path_suffix(cwd, depth)
   if cwd == "/" and depth == 1 then
      return "root"
   end
   local parts = {}
   for part in cwd:gmatch("[^/]+") do
      parts[#parts + 1] = part
   end
   if depth > #parts then
      return cwd
   end
   return table.concat(parts, "/", #parts - depth + 1)
end

--- Choose unique path suffixes for managed projects; other labels are reserved.
local function plan_labels(listed, newcomer)
   local reserved, entries = {}, {}
   for _, session in ipairs(listed) do
      local record = records[session.session_id]
      if record and record.automatic then
         entries[#entries + 1] = { id = session.session_id, cwd = record.cwd, label = record.label }
      else
         reserved[session.label] = true
      end
   end
   if newcomer.automatic then
      entries[#entries + 1] = newcomer
   else
      assert(not reserved[newcomer.label], "Session label is already in use: " .. newcomer.label)
      reserved[newcomer.label] = true
   end
   for _, entry in ipairs(entries) do
      -- Start at the saved depth so an expanded name does not shrink later.
      local _, slashes = entry.label:gsub("/", "")
      local depth = slashes + 1
      while true do
         local label = path_suffix(entry.cwd, depth)
         local taken = reserved[label]
         for _, other in ipairs(entries) do
            if other ~= entry and path_suffix(other.cwd, depth) == label then
               taken = true
            end
         end
         if not taken then
            entry.label = label
            break
         end
         assert(path_suffix(entry.cwd, depth + 1) ~= label, "Cannot disambiguate project label: " .. label .. "; choose an explicit label")
         depth = depth + 1
      end
   end
   return entries
end

local function terminal(cwd, command)
   return {
      block = {
         flavor = "com.superlogical.terminal.shell",
         options = { cwd = cwd, shell = config.shell, command = command, interactive = command ~= nil },
      },
   }
end

--- Give Rex.app time to apply new-window events before asking it to select one.
--- Config actions have no rex.sleep; rex.exec yields while the app processes events.
local function select_session(session)
   if session.created then
      local settled = fossilize(rex.exec({ "/bin/sleep", "0.2" }))
      assert(settled.ok, "Could not delay new-tab selection: " .. settled.stderr)
   end
   rex.client.queue("session.select", { session_id = session.session_id, window_id = session.window_id })
end

--- Open or reuse a project by its normalized absolute root, never its display label.
---@param args { cwd: string, label?: string, focus?: boolean }
function tyrannosession_rex.territorialize(args)
   local cwd = absolute(args.cwd)
   assert(fossilize(rex.exec({ "/bin/test", "-d", cwd })).ok, "Directory does not exist: " .. cwd)
   load_records()
   local listed = fossilize(rex.call("session.list")).sessions or {}
   local live = {}
   for _, session in ipairs(listed) do
      live[session.session_id] = session.label
   end
   for id in pairs(records) do
      if not live[id] then
         records[id] = nil
      end
   end
   for _, session in ipairs(listed) do
      if records[session.session_id] and records[session.session_id].cwd == cwd then
         save_records()
         local reused = { session_id = session.session_id, created = false }
         if args.focus ~= false then
            select_session(reused)
         end
         return reused
      end
   end

   local label = args.label
   for _, project in ipairs(config.projects) do
      if project.cwd == cwd then
         label = label or project.label
      end
   end
   local newcomer = { cwd = cwd, label = label or path_suffix(cwd, 1), automatic = label == nil }
   local planned = plan_labels(listed, newcomer)
   save_records()
   for _, entry in ipairs(planned) do
      if entry.id and live[entry.id] ~= entry.label then
         fossilize(rex.call("session.set_label", { session_id = entry.id, label = entry.label }))
         records[entry.id].label = entry.label
         save_records()
      end
   end

   local windows = {}
   for _, program in ipairs(config.programs) do
      windows[#windows + 1] = { layout = terminal(cwd, program) }
   end
   local claimed = fossilize(rex.call("session.create", { label = newcomer.label, initial_windows = windows }))
   records[claimed.session_id] = { cwd = cwd, label = newcomer.label, automatic = newcomer.automatic }
   save_records()
   local session = { session_id = claimed.session_id, window_id = claimed.initial_windows[#windows].window_id, created = true }
   if args.focus ~= false then
      select_session(session)
   end
   return session
end

--- Scan in the server action, where the configured roots and executables live.
local function candidates()
   local paths, seen = {}, {}
   local function add(path)
      path = absolute(path)
      if not seen[path] then
         paths[#paths + 1] = path
         seen[path] = true
      end
   end
   local hunt = { config.executables.fd, "--type=directory", "--max-depth=" .. config.max_depth, "." }
   local initial_count = #hunt
   for _, root in ipairs(config.roots) do
      if fossilize(rex.exec({ "/bin/test", "-d", root })).ok then
         hunt[#hunt + 1] = root
         add(root)
      end
   end
   assert(#hunt > initial_count, "None of the configured project roots exist")
   local sighted = fossilize(rex.exec(hunt))
   assert(sighted.ok, "Could not scan project directories: " .. sighted.stderr)
   for path in sighted.stdout:gmatch("[^\n]+") do
      add(path)
   end
   table.sort(paths)
   return { paths = paths, fzf = config.executables.fzf }
end

--- Run in the floating picker process; fetch all configuration-dependent data remotely.
function tyrannosession_rex.chomp()
   local found = fossilize(rex.invoke("tyrannosession_candidates"))
   local display, paths = {}, {}
   for _, cwd in ipairs(found.paths) do
      local label = cwd == home and "~" or (cwd:sub(1, #home + 1) == home .. "/" and "~" .. cwd:sub(#home + 1) or cwd)
      display[#display + 1] = label
      paths[label] = cwd
   end
   table.sort(display)
   if #display == 0 then
      return
   end
   local ambush = fossilize(rex.exec.start({ found.fzf }, {
      stdin = table.concat(display, "\n") .. "\n",
      stderr = function(data)
         io.write(data)
      end,
   }))
   local selected = fossilize(ambush:wait())
   if selected.code == 1 or selected.code == 130 then
      return
   end
   assert(selected.ok, "fzf exited with status " .. tostring(selected.code))
   local cwd = paths[selected.stdout:gsub("\n$", "")]
   assert(cwd, "Project picker returned an unknown directory")
   local session = fossilize(rex.invoke("territorialize", { cwd = cwd, focus = false }))
   select_session(session)
   return session
end

--- Register project actions. All API calls and state writes are deferred until use.
---@param options { script_path: string, roots?: string[], programs?: string[][], shell?: string, projects?: {cwd: string, label?: string}[], executables?: {fd?: string, fzf?: string, rex?: string}, bindings?: {picker?: string|false, new_tab?: string[]}, state_path?: string, max_depth?: integer }
function tyrannosession_rex.setup(options)
   assert(type(options) == "table", "setup expects a configuration table")
   local shell = options.shell or os.getenv("SHELL") or "/bin/sh"
   local executables = options.executables or {}
   local bin_dir = os.getenv("REX_BIN_DIR")
   config = {
      script_path = absolute(options.script_path),
      roots = {},
      projects = {},
      programs = options.programs or { { shell } },
      shell = shell,
      max_depth = options.max_depth or 1,
      state_path = absolute(options.state_path or ((os.getenv("XDG_STATE_HOME") or (home .. "/.local/state")) .. "/rex/tyrannosession.json")),
      executables = {
         fd = executables.fd or "fd",
         fzf = executables.fzf or "fzf",
         rex = executables.rex or (bin_dir and (bin_dir .. "/rex")) or "rex",
      },
   }
   assert(#config.programs > 0, "programs must contain at least one argument array")
   for _, root in ipairs(options.roots or { home .. "/Code" }) do
      config.roots[#config.roots + 1] = absolute(root)
   end
   for _, project in ipairs(options.projects or {}) do
      config.projects[#config.projects + 1] = { cwd = absolute(project.cwd), label = project.label }
   end
   records = nil

   rex.action({
      name = "territorialize",
      title = "Open Project Session",
      category = "Session",
      args = { cwd = "string", label = "string?", focus = "boolean?" },
      run = function(_, args)
         return tyrannosession_rex.territorialize(args)
      end,
   })
   rex.action({
      name = "hatch",
      title = "New Tab at Project Root",
      category = "Tab",
      run = function(ctx)
         if not ctx.session_id then
            rex.client.queue("client.tab.new")
            return
         end
         load_records()
         local record = records[ctx.session_id]
         if not record then
            rex.client.queue("client.tab.new")
            return
         end
         assert(fossilize(rex.exec({ "/bin/test", "-d", record.cwd })).ok, "Directory does not exist: " .. record.cwd)
         local window = fossilize(rex.session.new_window({
            session_id = ctx.session_id,
            focus = true,
            layout = terminal(record.cwd),
         }))
         select_session({ session_id = ctx.session_id, window_id = window.window_id, created = true })
         return { window_id = window.window_id }
      end,
   })
   rex.action({
      name = "tyrannosession_candidates",
      title = "List Project Directories",
      category = "Session",
      run = candidates,
   })
   rex.action({
      name = "pick_project_session",
      title = "Tyrannosession",
      category = "Session",
      run = function(ctx)
         assert(ctx.session_id and ctx.client_id, "Open the project picker from a Rex client session")
         local window_id
         if ctx.block_id then
            -- The app's visible tab can differ from the server's active window.
            local described = fossilize(rex.session.describe_block({ session_id = ctx.session_id, block_id = ctx.block_id }))
            assert(described.block.placement == "placed" and described.block.window_id, "The invoking pane is no longer in a window")
            window_id = described.block.window_id
         else
            -- Palette/CLI invocations may not identify a pane.
            window_id = fossilize(rex.session.view({ session_id = ctx.session_id })).active_window_id
         end
         return fossilize(rex.session.new_layer({
            session_id = ctx.session_id,
            window_id = window_id,
            bounds = { 0.35, 0.1, 0.3, 0.4 },
            focus = true,
            layout = {
               block = {
                  flavor = "com.superlogical.terminal.shell",
                  options = {
                     cwd = home,
                     shell = "none",
                     login = false,
                     command = { config.executables.rex, "--autostart=false", "-C", ctx.client_id, "do", config.script_path, "--session", ctx.session_id, "pick=true" },
                  },
               },
            },
         }))
      end,
   })
   local bindings = options.bindings or {}
   if bindings.picker ~= false then
      rex.bind(bindings.picker or "ctrl+b>f", "pick_project_session")
   end
   for _, key in ipairs(bindings.new_tab or {}) do
      rex.bind(key, "hatch")
   end
end

if rex.args and rex.args.pick then
   local ok, result = pcall(tyrannosession_rex.chomp)
   if not ok then
      io.write("\n" .. tostring(result) .. "\nPress Enter to close.\n")
      local _ = io.read("*l")
      rex.stop(1)
   end
   return result
end

return tyrannosession_rex
