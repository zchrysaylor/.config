rex.bind("ctrl+b>shift+5", "pane.split.right")
rex.bind("ctrl+b>shift+[Quote]", "pane.split.down")
rex.bind("ctrl+b>h", "pane.focus.left")
rex.bind("ctrl+b>j", "pane.focus.down")
rex.bind("ctrl+b>k", "pane.focus.up")
rex.bind("ctrl+b>l", "pane.focus.right")
rex.bind("ctrl+b>x", "client.close")
rex.bind("ctrl+b>shift+x", "client.tab.close")
rex.bind("ctrl+b>shift+d", "session.close")

for index = 1, 9 do
  rex.bind("ctrl+b>" .. index, "client.tab.goto", { index = index })
end

-- Herdr workspace shortcuts, mapped to Rex sessions.
rex.bind("ctrl+b>shift+9", "session.previous")
rex.bind("ctrl+b>shift+0", "session.next")

local home = assert(os.getenv("HOME"), "HOME must be set")
local project_sessions = {
  { key = "shift+c", cwd = home .. "/.config" },
  { key = "shift+g", cwd = home .. "/Documents/geumgo" },
  { key = "d", cwd = home .. "/Code/IdeaProjects/deliveryhero" },
  { key = "shift+o", cwd = home .. "/Code/IdeaProjects/deliveryhero/log-vendor-order-management-application" },
  { key = "shift+v", cwd = home .. "/Code/verin" },
  { key = "shift+[Backquote]", cwd = home },
}

for _, project in ipairs(project_sessions) do
  rex.bind("ctrl+b>" .. project.key, "tyrannosession", { cwd = project.cwd })
end

local config = os.getenv("XDG_CONFIG_HOME") or (home .. "/.config")
require("tyrannosession-rex").setup({
  roots = {
    home .. "/Code",
    home .. "/Code/IdeaProjects/deliveryhero",
    home .. "/forge",
    home .. "/Documents/geumgo",
  },
  programs = { { "pi" }, { "zsh" } },
  shell = "/bin/zsh",
  executables = {
    fd = "/opt/homebrew/bin/fd",
  },
  bindings = {
    picker = "ctrl+b>f",
    new_tab = { "ctrl+b>c", "cmd+t" },
  },
})

local annotator_path = config .. "/rex/tyrannotator-rex.lua"
dofile(annotator_path).setup(annotator_path)
