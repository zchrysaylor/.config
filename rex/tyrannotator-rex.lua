--- Terminal-selection annotations for Rex, with Neovim.
local tyrannotator_rex = {}

-- Select text with Copy on selection enabled (or Cmd+C), then Ctrl+A A to annotate.
-- Ctrl+A M reviews annotations; Ctrl+A Enter pastes without submitting.
-- Neovim: :wq / Ctrl+S accepts the draft; :cq cancels it.
local home = assert(os.getenv("HOME"))
local state_dir = (os.getenv("XDG_STATE_HOME") or (home .. "/.local/state")) .. "/rex-annotate"
local rex_bin_dir = os.getenv("REX_BIN_DIR") or (home .. "/Library/Application Support/com.superlogical.rex/RexServer/Versions/Current/Rex Server.app/Contents/MacOS")
local rex_path = rex_bin_dir .. "/rex"
local nvim_path = "/opt/homebrew/bin/nvim"
local heading = "# Annotations on terminal selections\n\n"

--- Return a Rex result, raising an error if the call failed.
---@generic T
---@param result T? Result of the Rex call; nil indicates failure.
---@param err string? Error message when the call failed.
---@return T result The successful result, including false.
local function checked(result, err)
   if result == nil then
      error(err, 0)
   end
   return result
end

--- Read a saved document, treating an unavailable file as an empty document.
---@param path string File to read.
---@return string text File contents, or an empty string if the file cannot be opened.
local function read_file(path)
   local file = io.open(path, "r")
   if not file then
      return ""
   end
   local text = file:read("*a")
   file:close()
   return text
end

--- Replace a document's contents, raising an error if writing fails.
---@param path string File to write.
---@param text string Complete document contents.
local function write_file(path, text)
   local file = assert(io.open(path, "w"))
   assert(file:write(text))
   assert(file:close())
end

--- Keep commented sections and renumber them, leaving headings inside selections alone.
---@param text string Annotation document, possibly containing uncommented drafts.
---@return string document Markdown containing only commented annotations.
---@return integer count Number of retained annotations.
function tyrannotator_rex.normalize(text)
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

--- Format a selection as an annotation section with an empty comment.
---@param selection string Selected terminal text.
---@param number integer Annotation number to put in the heading.
---@return string section Markdown section ready for a comment.
function tyrannotator_rex.section(selection, number)
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
   return "## Annotation " .. tostring(number) .. "\n" .. quoted .. "\n> \n"
end

--- Configure the Neovim draft buffer and accept saved edits on a successful exit.
--- Called inside Neovim, not a Rex action. :cq discards the draft.
---@param base_path string Pane-scoped path without the document suffix.
---@param capture boolean Whether to start inserting at the new comment.
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
            write_file(base_path .. ".md", (tyrannotator_rex.normalize(read_file(base_path .. ".draft.md"))))
         end
         os.remove(base_path .. ".draft.md")
      end,
   })
   if capture then
      vim.cmd("normal! G$")
      vim.cmd("startinsert!")
   end
end

--- Forward server-side selections to the config's in-memory, per-pane cache.
--- Normal Rex.app selections use the clipboard instead of this event stream.
---@param token string Identifies the configuration that started this CLI listener.
function tyrannotator_rex.watch(token)
   --- Send a selection or heartbeat, stopping if a newer configuration replaced this one.
   ---@param args { session_id?: string, block_id?: string, text?: string, token?: string }
   local function remember_selection(args)
      args.token = token
      local reply = rex.invoke("annotate_cache_selection", args)
      if not reply or not reply.active then
         rex.stop()
      end
   end

   --- Read a selection, including stored blobs, and forward it to the owning pane's cache.
   ---@param ctx { session_id: string, block_id: string } Source pane's context.
   ---@param event { text?: string, id?: integer } Selection text or stored blob identifier.
   local function cache_selection(ctx, event)
      local text = event.text
      if not text and event.id then
         local parts = {}
         local offset = 0
         local part
         repeat
            part = checked(rex.call("com.superlogical.terminal.blob_read", {
               session_id = ctx.session_id,
               block_id = ctx.block_id,
               args = { id = event.id, offset = offset },
            }))
            parts[#parts + 1] = part.data
            offset = offset + #part.data
         until part.eof
         text = table.concat(parts)
      end
      if text then
         remember_selection({ session_id = ctx.session_id, block_id = ctx.block_id, text = text })
      end
   end

   rex.on("terminal.selection_copied", cache_selection)
   -- A config reload replaces the cache; let its old listener exit without PID files.
   rex.every(5, function()
      remember_selection({})
   end)
end

--- Register annotation actions and key bindings, then start the selection listener.
---@param script_path string Absolute path to this plugin, used by Neovim and the listener.
function tyrannotator_rex.setup(script_path)
   ---@type table<string, string>
   local selections = {}
   ---@type table<string, { block_id: string, layer_id: string }>
   local editors = {}
   ---@type table<string, string>
   local targets = {}
   local listener_token = os.tmpname()
   os.remove(listener_token)
   local directory = checked(rex.exec({ "/bin/mkdir", "-p", state_dir }))
   assert(directory.ok, directory.stderr)

   --- Resolve an editor popup back to the pane whose annotations it edits.
   ---@param ctx { session_id: string, block_id: string } Invoking pane's context.
   ---@return string session_id Target session.
   ---@return string block_id Target pane.
   local function get_target(ctx)
      return ctx.session_id, targets[ctx.block_id] or ctx.block_id
   end

   --- Build the shared key for a pane's files, selection, and editor.
   ---@param session_id string Target session.
   ---@param block_id string Target pane.
   ---@return string key Pane-scoped identifier.
   local function get_pane_key(session_id, block_id)
      return session_id .. "--" .. block_id
   end

   --- Focus an existing editor, forgetting its record if the popup has closed.
   ---@param session_id string Target session.
   ---@param block_id string Target pane.
   ---@return boolean focused Whether an existing editor was focused.
   local function focus_editor(session_id, block_id)
      local pane_key = get_pane_key(session_id, block_id)
      local editor = editors[pane_key]
      if not editor then
         return false
      end
      local focused = rex.session.focus_block({ session_id = session_id, block_id = editor.block_id })
      if not focused then
         targets[editor.block_id] = nil
         editors[pane_key] = nil
         return false
      end
      checked(rex.session.raise_layer({ session_id = session_id, layer_id = editor.layer_id }))
      return true
   end

   --- Open or focus the target pane's annotation document in a floating Neovim terminal.
   ---@param ctx { session_id: string, block_id: string } Invoking pane's context.
   ---@param capture boolean Whether to append the current selection before editing.
   local function open_editor(ctx, capture)
      local session_id, block_id = get_target(ctx)
      if focus_editor(session_id, block_id) then
         return
      end
      local pane_key = get_pane_key(session_id, block_id)
      local base_path = state_dir .. "/" .. pane_key
      local text, count = tyrannotator_rex.normalize(read_file(base_path .. ".md"))
      if capture then
         -- Rex.app selects locally without emitting selection_copied. Its copy-on-select
         -- clipboard is authoritative here; an older server-side selection may be stale.
         local clipboard = rex.exec({ "/usr/bin/pbpaste" })
         local selection = (clipboard and clipboard.ok) and clipboard.stdout or selections[pane_key]
         assert(selection and selection:find("%S"), "Select and copy text first (or enable Copy on selection)")
         if text == "" then
            text = heading
         end
         text = text .. (count > 0 and "\n" or "") .. tyrannotator_rex.section(selection, count + 1)
      else
         assert(count > 0, "No annotations collected for this pane")
      end
      write_file(base_path .. ".draft.md", text)
      local view = checked(rex.session.view({ session_id = session_id }))
      local layer = checked(rex.session.new_layer({
         session_id = session_id,
         window_id = view.active_window_id,
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
                  command = {
                     nvim_path,
                     "--clean",
                     "-n",
                     "-i",
                     "NONE",
                     base_path .. ".draft.md",
                     "-c",
                     string.format("lua dofile(%q).edit(%q, %s)", script_path, base_path, tostring(capture)),
                  },
               },
            },
         },
      }))
      editors[pane_key] = { block_id = layer.block_ids[1], layer_id = layer.layer_id }
      targets[layer.block_ids[1]] = block_id
   end

   rex.action({
      name = "annotate_cache_selection",
      title = "Cache Terminal Selection",
      args = { token = "string", session_id = "string?", block_id = "string?", text = "string?" },
      run = function(_, args)
         if args.token ~= listener_token then
            return { active = false }
         end
         if args.text then
            selections[get_pane_key(args.session_id, args.block_id)] = args.text
         end
         return { active = true }
      end,
   })
   rex.action({
      name = "annotate_capture",
      title = "Tyrannotator: Annotate Selection",
      category = "Annotations",
      run = function(ctx)
         open_editor(ctx, true)
      end,
   })
   rex.action({
      name = "annotate_manage",
      title = "Tyrannotator: Review Annotations",
      category = "Annotations",
      run = function(ctx)
         open_editor(ctx, false)
      end,
   })
   rex.action({
      name = "annotate_paste",
      title = "Tyrannotator: Paste Annotations",
      category = "Annotations",
      run = function(ctx)
         local session_id, block_id = get_target(ctx)
         assert(not focus_editor(session_id, block_id), "Save and close the annotation editor before pasting")
         local base_path = state_dir .. "/" .. get_pane_key(session_id, block_id)
         local text, count = tyrannotator_rex.normalize(read_file(base_path .. ".md"))
         assert(count > 0, "No annotations collected for this pane")
         checked(rex.call("block.event", {
            session_id = session_id,
            block_id = block_id,
            event = { type = "paste", payload = { text = text } },
         }))
         write_file(base_path .. ".last-pasted.md", text)
         write_file(base_path .. ".md", "")
      end,
   })
   rex.bind("ctrl+a>a", "annotate_capture")
   rex.bind("ctrl+a>m", "annotate_manage")
   rex.bind("ctrl+a>enter", "annotate_paste")
   checked(rex.exec.start({
      rex_path,
      "--autostart=false",
      "do",
      script_path,
      "--all",
      "watch=true",
      "token=" .. listener_token,
   }, { detach = true, stdout = false, stderr = false }))
end

if rex and rex.args and rex.args.watch then
   tyrannotator_rex.watch(rex.args.token)
   return
end
return tyrannotator_rex
