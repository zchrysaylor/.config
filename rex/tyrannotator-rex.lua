--- Terminal-selection annotations for Rex on macOS.
local tyrannotator_rex = {}

-- Ctrl+A A enters Annotate mode. Enable Copy on Selection, drag to open Neovim,
-- and press Esc outside Neovim to exit the mode.
-- Ctrl+A M reviews, Ctrl+A D deletes saved notes, and Ctrl+A Enter pastes.
local home = assert(os.getenv("HOME"))
local state_dir = (os.getenv("XDG_STATE_HOME") or (home .. "/.local/state")) .. "/rex-annotate"
local rex_bin_dir = os.getenv("REX_BIN_DIR") or (home .. "/Library/Application Support/com.superlogical.rex/RexServer/Versions/Current/Rex Server.app/Contents/MacOS")
local rex_path = rex_bin_dir .. "/rex"
local heading = "# Annotations on terminal selections\n\n"

--- Read a saved document, treating a missing file as empty.
local function read_file(path)
   local file = io.open(path, "r")
   if not file then
      return ""
   end
   local text = file:read("*a")
   file:close()
   return text
end

local function write_file(path, text)
   local file = assert(io.open(path, "w"))
   assert(file:write(text))
   assert(file:close())
end

--- Keep commented sections and renumber them, leaving headings inside selections alone.
---@param text string
---@return string document
---@return integer count
local function normalize(text)
   local notes = {}
   ---@type { lines: string[], commented: boolean }?
   local current
   ---@type string?
   local fence

   --- Append the current section if it contains a comment outside its code fences.
   local function append_note()
      if current and current.commented then
         local body = table.concat(current.lines, "\n"):gsub("%s+$", "")
         notes[#notes + 1] = "## Annotation " .. tostring(#notes + 1) .. "\n" .. body
      end
   end

   for line in (text .. "\n"):gmatch("([^\n]*)\n") do
      local marks = line:match("^%s*(```+)") or line:match("^%s*(~~~+)")
      if not fence and line:match("^## Annotation %d+") then
         append_note()
         current = { lines = {}, commented = false }
      elseif current then
         current.lines[#current.lines + 1] = line
         if not fence then
            local comment = line:match("^>%s*(.*)")
            if comment and comment:find("%S") then
               current.commented = true
            end
         end
      end
      if marks then
         if not fence then
            fence = marks
         elseif marks:sub(1, 1) == fence:sub(1, 1) and #marks >= #fence and line:match("^%s*[`~]+%s*$") then
            fence = nil
         end
      end
   end
   append_note()
   if #notes == 0 then
      return "", 0
   end
   return heading .. table.concat(notes, "\n\n") .. "\n", #notes
end

--- Fence multiline selections with more backticks than any run in the quote.
local function section(selection, number)
   local quoted
   if selection:find("\n", 1, true) then
      local width = 3
      for marks in selection:gmatch("`+") do
         width = math.max(width, #marks + 1)
      end
      local fence = string.rep("`", width)
      quoted = "Comment on:\n" .. fence .. "text\n" .. selection .. "\n" .. fence
   else
      quoted = 'Comment on: "' .. selection .. '"'
   end
   return ("## Annotation %d\n%s\n> \n"):format(number, quoted)
end

--- Accept the Neovim draft on a successful exit. :cq discards it.
---@param base_path string Pane-scoped path without the document suffix.
---@param capture boolean Start at the new comment rather than in review mode.
function tyrannotator_rex.edit(base_path, capture)
   vim.bo.filetype = "markdown"
   vim.bo.formatoptions = "tcroqj"
   vim.opt.laststatus = 2
   vim.opt.statusline = " Tyrannotator | :wq / Ctrl-S save | :cq cancel %=%l:%c "
   vim.keymap.set({ "n", "i" }, "<C-s>", "<Esc><Cmd>wq<CR>", { buffer = true })
   vim.api.nvim_create_autocmd("VimLeavePre", {
      once = true,
      callback = function()
         if vim.v.exiting == nil or vim.v.exiting == 0 then
            write_file(base_path .. ".md", (normalize(read_file(base_path .. ".draft.md"))))
         end
         os.remove(base_path .. ".draft.md")
      end,
   })
   if capture then
      vim.cmd("normal! G$")
      vim.cmd("startinsert!")
   end
end

--- Register capture, review, and paste actions.
---@param script_path string Absolute path to this plugin.
function tyrannotator_rex.setup(script_path)
   local watcher_path = script_path:gsub("%.lua$", "-watch.js")
   local active -- one mode at a time, because the Mac has one clipboard
   ---@type table<string, { block_id: string, layer_id: string }>
   local editors = {}
   ---@type table<string, string>
   local targets = {}
   local directory = assert(rex.exec({ "/bin/mkdir", "-p", state_dir }))
   assert(directory.ok, directory.stderr)

   --- Use the source pane in Annotate mode or when invoked from its editor.
   ---@param ctx { client_id?: string, session_id?: string, block_id?: string }
   ---@return string session_id
   ---@return string block_id
   ---@return string base_path
   local function get_target(ctx)
      if active and active.client_id == ctx.client_id and active.watcher:running() then
         return active.session_id, active.block_id, active.path
      end
      local session_id = assert(ctx.session_id, "No Rex session selected")
      local block_id = assert(ctx.block_id, "No Rex pane selected")
      block_id = targets[block_id] or block_id
      return session_id, block_id, state_dir .. "/" .. session_id .. "--" .. block_id
   end

   --- Find an open editor without changing focus.
   local function get_editor(session_id, base_path)
      local editor = editors[base_path]
      if editor and not rex.session.describe_block({ session_id = session_id, block_id = editor.block_id }) then
         targets[editor.block_id] = nil
         editors[base_path] = nil
         return nil
      end
      return editor
   end

   local function focus_editor(session_id, base_path)
      local editor = get_editor(session_id, base_path)
      if not editor then
         return false
      end
      assert(rex.session.focus_block({ session_id = session_id, block_id = editor.block_id }))
      assert(rex.session.raise_layer({ session_id = session_id, layer_id = editor.layer_id }))
      return true
   end

   --- Open a draft, optionally appending a new selection for comment.
   local function open_editor(session_id, block_id, base_path, selection, window_id)
      if focus_editor(session_id, base_path) then
         return
      end
      local text, count = normalize(read_file(base_path .. ".md"))
      if selection then
         text = (count > 0 and text .. "\n" or heading) .. section(selection, count + 1)
      else
         assert(count > 0, "No annotations collected for this pane")
      end
      write_file(base_path .. ".draft.md", text)
      local layer = assert(rex.session.new_layer({
         session_id = session_id,
         window_id = window_id or assert(rex.session.view({ session_id = session_id })).active_window_id,
         bounds = { 0.1, 0.1, 0.8, 0.8 },
         focus = true,
         layout = {
            block = {
               flavor = "com.superlogical.terminal.shell",
               label = "Tyrannotator",
               options = {
                  cwd = home,
                  shell = "none",
                  login = false,
                  path_prepend = { "/opt/homebrew/bin", "/usr/local/bin" },
                  command = {
                     "/usr/bin/env", "nvim",
                     "--clean",
                     "-n",
                     "-i",
                     "NONE",
                     base_path .. ".draft.md",
                     "-c",
                     string.format("lua dofile(%q).edit(%q, %s)", script_path, base_path, tostring(selection ~= nil)),
                  },
               },
            },
         },
      }))
      editors[base_path] = { block_id = layer.block_ids[1], layer_id = layer.layer_id }
      targets[layer.block_ids[1]] = block_id
   end

   rex.action({
      name = "annotate_enter",
      title = "Tyrannotator: Enter Annotate Mode",
      description = "Make a terminal selection with Copy on Selection enabled.",
      category = "Annotations",
      run = function(ctx)
         local client_id = assert(ctx.client_id, "Enter Annotate mode from Rex.app")
         if active and active.watcher:running() then
            assert(active.client_id == client_id, "Annotate mode is active in another Rex client")
            return
         end
         local session_id, block_id, base_path = get_target(ctx)
         assert(not focus_editor(session_id, base_path), "Save and close the annotation editor first")

         local token = os.tmpname()
         os.remove(token)
         local watcher = assert(rex.exec.start({
            "/usr/bin/osascript", "-l", "JavaScript", watcher_path, rex_path, token, session_id, block_id,
         }, { detach = true, stdout = false, stderr = false }))
         active = {
            token = token,
            client_id = client_id,
            session_id = session_id,
            block_id = block_id,
            path = base_path,
            watcher = watcher,
         }
         rex.client.queue("client.mode.enter", { name = "annotate" })
      end,
   })
   rex.action({
      name = "annotate_exit",
      title = "Exit Annotate Mode",
      category = "Annotations",
      run = function(ctx)
         if ctx.origin == "key" and targets[ctx.block_id] then
            rex.client.queue("pane.send_key", { key = "escape" })
            return
         end
         if active and active.client_id == ctx.client_id then
            local watcher = active.watcher
            active = nil
            watcher:kill()
         end
         rex.client.queue("client.mode.exit")
      end,
   })
   rex.action({
      name = "annotate_selection",
      title = "Tyrannotator: Open Captured Selection",
      category = "Annotations",
      args = { token = "string", text = "string?" },
      run = function(_, args)
         local mode = active
         if not mode or mode.token ~= args.token then
            return { active = false }
         end
         local selection = args.text
         if not selection or not selection:find("%S") or get_editor(mode.session_id, mode.path) then
            return { active = true }
         end

         -- Copy on Selection doesn't identify the pane. Don't capture from another tab or pane.
         local view = assert(rex.session.view({ session_id = mode.session_id }))
         for _, window in ipairs(view.windows or {}) do
            if window.window_id == view.active_window_id and window.focused_block_id == mode.block_id then
               open_editor(mode.session_id, mode.block_id, mode.path, selection, window.window_id)
               break
            end
         end
         return { active = true }
      end,
   })
   rex.action({
      name = "annotate_manage",
      title = "Tyrannotator: Review Annotations",
      category = "Annotations",
      run = function(ctx)
         open_editor(get_target(ctx))
      end,
   })
   rex.action({
      name = "annotate_delete",
      title = "Tyrannotator: Delete Saved Annotations",
      category = "Annotations",
      run = function(ctx)
         local session_id, _, base_path = get_target(ctx)
         assert(not get_editor(session_id, base_path), "Close Neovim before deleting saved annotations")
         local deleted = assert(rex.exec({ "/bin/rm", "-f", base_path .. ".md" }))
         assert(deleted.ok, deleted.stderr)
      end,
   })
   rex.action({
      name = "annotate_paste",
      title = "Tyrannotator: Paste Annotations",
      category = "Annotations",
      run = function(ctx)
         local session_id, block_id, base_path = get_target(ctx)
         assert(not focus_editor(session_id, base_path), "Save and close the annotation editor before pasting")
         local text, count = normalize(read_file(base_path .. ".md"))
         assert(count > 0, "No annotations collected for this pane")
         assert(rex.call("block.event", {
            session_id = session_id,
            block_id = block_id,
            event = { type = "paste", payload = { text = text } },
         }))
         write_file(base_path .. ".last-pasted.md", text)
         write_file(base_path .. ".md", "")
      end,
   })
   rex.bind("ctrl+a>a", "annotate_enter")
   local note_actions = {
      ["ctrl+a>m"] = "annotate_manage",
      ["ctrl+a>d"] = "annotate_delete",
      ["ctrl+a>enter"] = "annotate_paste",
   }
   for key, action in pairs(note_actions) do
      rex.bind(key, action)
      rex.bind("annotate/" .. key, action)
   end

   -- Block configured shortcuts, not ordinary keys: the floating Neovim needs them.
   rex.bind("annotate/escape", "annotate_exit")
   rex.unbind("annotate/ctrl+b")
   for _, binding in ipairs(rex.bindings()) do
      if not binding.mode and not note_actions[binding.key] then
         rex.unbind("annotate/" .. binding.key)
      end
   end
end

return tyrannotator_rex
