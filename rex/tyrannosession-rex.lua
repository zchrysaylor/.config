--- Project sessions and the floating project picker for Rex.
local tyrannosession_rex = {}

local home = assert(os.getenv("HOME"), "HOME must be set")
local fd_path = "/opt/homebrew/bin/fd"
local fzf_path = "/opt/homebrew/bin/fzf"
local rex_bin_dir = os.getenv("REX_BIN_DIR") or (home .. "/Library/Application Support/com.superlogical.rex/RexServer/Versions/Current/Rex Server.app/Contents/MacOS")
local rex_path = rex_bin_dir .. "/rex"
local stomping_grounds = {
   home .. "/Code",
   home .. "/Code/IdeaProjects/deliveryhero",
   home .. "/forge",
   home .. "/Documents/geumgo",
}

--- Return a Rex result, raising an error if the call failed.
---@generic T
---@param result T? Result of the Rex call; nil indicates failure.
---@param err string? Error message when the call failed.
---@return T result The successful result, including false.
local function fossilize(result, err)
   if result == nil then
      error(err, 0)
   end
   return result
end

local project_sessions = {}
local session_roots = {}

--- Open or reuse a project's session.
---@param args { cwd: string, label?: string, focus?: boolean } Focus defaults to true.
---@return { session_id: string, window_id?: string, created: boolean } session
function tyrannosession_rex.territorialize(args)
   local scent = args.label
   if not scent then
      for _, stomping_ground in ipairs(project_sessions) do
         if stomping_ground.cwd == args.cwd then
            scent = stomping_ground.label
            break
         end
      end
      scent = scent or (args.cwd:match("([^/]+)/?$") or "root"):gsub("%.", "_")
   end

   local listed = fossilize(rex.call("session.list"))
   for _, territory in ipairs(listed.sessions or {}) do
      if territory.label == scent then
         session_roots[territory.session_id] = args.cwd
         if args.focus ~= false then
            rex.client.queue("session.select", { session_id = territory.session_id })
         end
         return { session_id = territory.session_id, created = false }
      end
   end

   if not fossilize(rex.exec({ "/bin/test", "-d", args.cwd })).ok then
      error("Directory does not exist: " .. args.cwd, 0)
   end

   local claimed = fossilize(rex.call("session.create", {
      label = scent,
      initial_windows = {
         {
            layout = {
               block = {
                  flavor = "com.superlogical.terminal.shell",
                  options = { cwd = args.cwd, shell = "/bin/zsh", initial_input = "pi\n" },
               },
            },
         },
         {
            layout = {
               block = {
                  flavor = "com.superlogical.terminal.shell",
                  options = { cwd = args.cwd, shell = "/bin/zsh" },
               },
            },
         },
      },
   }))
   session_roots[claimed.session_id] = args.cwd

   local window_id = claimed.initial_windows[2].window_id
   if args.focus ~= false then
      rex.client.queue("session.select", { session_id = claimed.session_id, window_id = window_id })
   end
   return { session_id = claimed.session_id, window_id = window_id, created = true }
end

--- Pick a project directory and open or reuse its session.
---@return { session_id: string, window_id?: string, created: boolean }? session Nil when the picker is cancelled or has no match.
function tyrannosession_rex.chomp()
   --- Record a directory by its home-relative display path, removing trailing slashes.
   ---@param sightings table<string, string> Lookup from display paths to absolute paths to update.
   ---@param prey string Absolute directory path beneath HOME.
   local function stalk(sightings, prey)
      prey = prey:gsub("/+$", "")
      sightings[prey:sub(#home + 2)] = prey
   end

   local sightings = {}
   local hunt = { fd_path, "--type=directory", "--max-depth=1", "." }
   local initial_count = #hunt
   for _, prey in ipairs(stomping_grounds) do
      if fossilize(rex.exec({ "/bin/test", "-d", prey })).ok then
         hunt[#hunt + 1] = prey
         stalk(sightings, prey)
      end
   end
   if #hunt == initial_count then
      error("None of the configured stomping grounds exist!", 0)
   end

   local sighted = fossilize(rex.exec(hunt))
   if not sighted.ok then
      error("The hunt failed: " .. sighted.stderr, 0)
   end
   for prey in sighted.stdout:gmatch("[^\n]+") do
      stalk(sightings, prey)
   end

   local stalked = {}
   for prey in pairs(sightings) do
      stalked[#stalked + 1] = prey
   end
   table.sort(stalked)
   if #stalked == 0 then
      error("No prey were stalked!", 0)
   end

   local ambush = fossilize(rex.exec.start({ fzf_path }, {
      stdin = table.concat(stalked, "\n") .. "\n",
      stderr = function(data)
         io.write(data)
      end,
   }))
   local chomped = fossilize(ambush:wait())
   -- 1: no match was selected; 130: fzf picker was cancelled (e.g. Ctrl+C)
   if chomped.code == 1 or chomped.code == 130 then
      return
   end
   if not chomped.ok then
      error("fzf exited with status " .. tostring(chomped.code), 0)
   end

   local prey = chomped.stdout:gsub("\n$", "")
   local cwd = sightings[prey]
   if not cwd then
      error("The ambush returned an unknown prey... how did that happen?", 0)
   end

   local session = fossilize(rex.invoke("territorialize", { cwd = cwd, focus = false }))
   rex.client.queue("session.select", { session_id = session.session_id, window_id = session.window_id })
   return session
end

--- Register project-session actions and the floating picker's key binding.
---@param script_path string Absolute path to this plugin, used to launch the picker.
---@param projects { cwd: string, label: string }[]? Project shortcuts.
function tyrannosession_rex.setup(script_path, projects)
   --- Open a shell tab at the project root, falling back to Rex's default new tab.
   ---@param ctx { session_id?: string } Rex action context.
   ---@return { window_id: string }? window Nil when using Rex's default action.
   local function hatch(ctx)
      if not ctx.session_id then
         rex.client.queue("client.tab.new")
         return
      end

      local view = fossilize(rex.session.view({ session_id = ctx.session_id }))
      local root = session_roots[ctx.session_id]
      for _, project in ipairs(project_sessions) do
         if project.label == view.label then
            root = project.cwd
            break
         end
      end
      if not root then
         rex.client.queue("client.tab.new")
         return
      end

      if not fossilize(rex.exec({ "/bin/test", "-d", root })).ok then
         error("Directory does not exist: " .. root, 0)
      end

      local window = fossilize(rex.session.new_window({
         session_id = ctx.session_id,
         focus = true,
         layout = {
            block = {
               flavor = "com.superlogical.terminal.shell",
               options = { cwd = root, shell = "/bin/zsh" },
            },
         },
      }))
      rex.client.queue("session.select", { session_id = ctx.session_id, window_id = window.window_id })
      return { window_id = window.window_id }
   end

   project_sessions = projects or {}
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
      run = hatch,
   })
   rex.action({
      name = "pick_project_session",
      title = "Tyrannosession",
      category = "Session",
      run = function(ctx)
         local view = fossilize(rex.session.view({ session_id = ctx.session_id }))
         return fossilize(rex.session.new_layer({
            session_id = ctx.session_id,
            window_id = view.active_window_id,
            bounds = { 0.35, 0.1, 0.3, 0.4 },
            focus = true,
            layout = {
               block = {
                  flavor = "com.superlogical.terminal.shell",
                  options = {
                     cwd = home,
                     shell = "none",
                     login = false,
                     command = {
                        rex_path,
                        "--autostart=false",
                        "-C",
                        ctx.client_id,
                        "do",
                        script_path,
                        "--session",
                        ctx.session_id,
                        "pick=true",
                     },
                  },
               },
            },
         }))
      end,
   })
   rex.bind("ctrl+b>f", "pick_project_session")
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
