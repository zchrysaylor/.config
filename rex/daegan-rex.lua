---Open a tab with one Pi pane per model.
local Daegan = {}

---@alias Daegan.Thinking "off"|"minimal"|"low"|"medium"|"high"|"xhigh"|"max"
---@class Daegan.Model
---@field id string Pi provider/model identifier.
---@field nickname? string Pane label; defaults to the model identifier.
---@field thinking? Daegan.Thinking Omit to use Pi's default.

---Add `thinking = "high"` to an entry to set its thinking level.
---@type Daegan.Model[]
local models = {
   { id = "litellm/gpt-6.1-terra", thinking = "medium", nickname = "Terra" },
   { id = "litellm/gpt-6-luna", thinking = "high", nickname = "Luna" },
   -- { id = "pi-claude-cli/claude-haiku-5-5", thinking = "high", nickname = "Haiku" },
   { id = "litellm/gpt-6-luna", thinking = "low" },
}

---@type string
local prompt = [[Perform an adversarial code review on uncommitted changes. Always check for adherence to the existing idiomatic patterns and style.]]

---Create a terminal running Pi with the shared prompt.
---@param model Daegan.Model
---@param cwd string? Working directory of the originating pane, if available.
---@param prompt_text string Prompt to send to Pi.
---@return table layout
local function pi_pane(model, cwd, prompt_text)
   local command = { "pi", "--model", model.id }
   if model.thinking then
      command[#command + 1] = "--thinking"
      command[#command + 1] = model.thinking
   end
   command[#command + 1] = "--"
   command[#command + 1] = prompt_text

   return rex.layout.block({
      flavor = "com.superlogical.terminal.shell",
      label = (model.nickname or model.id) .. " Eongwan",
      options = {
         cwd = cwd,
         command = command,
         interactive = true,
         exit = { on_completion = false },
      },
   })
end

---Register the Daegan action.
function Daegan.setup()
   rex.action({
      name = "daegan",
      title = "Open Daegan",
      description = "Open a tab with one Pi pane per model.",
      category = "Tab",
      ---@param ctx { session_id: string, block_id?: string }
      run = function(ctx)
         assert(#models > 0, "Daegan needs at least one model")
         local prompt_text, why, detail = rex.ui.input({
            title = "Daegan prompt",
            placeholder = "Leave blank to use the default prompt",
         })
         if prompt_text == nil then
            if why == "cancelled" then
               return
            end
            error("Could not get prompt: " .. tostring(why) .. (detail and (": " .. detail) or ""), 0)
         end
         if prompt_text == "" then
            prompt_text = prompt
         end

         local process = ctx.block_id and rex.block.call("com.superlogical.terminal", "process", { block_id = ctx.block_id })
         local cwd = process and process.foreground and process.foreground.cwd

         local layout = pi_pane(models[#models], cwd, prompt_text)
         for i = #models - 1, 1, -1 do
            layout = rex.layout.horizontal(1 / (#models - i + 1), pi_pane(models[i], cwd, prompt_text), layout)
         end

         local window = assert(rex.session.new_window({
            session_id = ctx.session_id,
            window_label = "daegan",
            focus = true,
            layout = layout,
         }))
         -- Let the app receive the new window before selecting it, as in Tyrannosession.
         local settled = assert(rex.exec({ "/bin/sleep", "0.2" }))
         assert(settled.ok, "Could not delay new-tab selection: " .. settled.stderr)
         rex.client.queue("session.select", { session_id = ctx.session_id, window_id = window.window_id })
      end,
   })
end

return Daegan
