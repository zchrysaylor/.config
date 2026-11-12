rex.bind("ctrl+b>c", "hatch")
rex.bind("cmd+t", "hatch")
rex.bind("ctrl+b>shift+5", "pane.split.right")
rex.bind("ctrl+b>shift+[Quote]", "pane.split.down")
rex.bind("ctrl+b>h", "pane.focus.left")
rex.bind("ctrl+b>j", "pane.focus.down")
rex.bind("ctrl+b>k", "pane.focus.up")
rex.bind("ctrl+b>l", "pane.focus.right")
rex.bind("ctrl+b>x", "client.close")
rex.bind("ctrl+b>shift+x", "client.tab.close")

for index = 1, 9 do
  rex.bind("ctrl+b>" .. index, "client.tab.goto", { index = index })
end

-- Herdr workspace shortcuts, mapped to Rex sessions.
rex.bind("ctrl+b>shift+9", "session.previous")
rex.bind("ctrl+b>shift+0", "session.next")

local home = assert(os.getenv("HOME"), "HOME must be set")
local project_sessions = {
  { key = "shift+c", cwd = home .. "/.config", label = ".config" },
  { key = "shift+g", cwd = home .. "/Documents/geumgo", label = "geumgo" },
  { key = "d", cwd = home .. "/Code/IdeaProjects/deliveryhero", label = "deliveryhero" },
  {
    key = "shift+o",
    cwd = home .. "/Code/IdeaProjects/deliveryhero/log-vendor-order-management-application",
    label = "otv2",
  },
  { key = "shift+v", cwd = home .. "/Code/verin", label = "verin" },
  { key = "shift+[Backquote]", cwd = home, label = "home" },
}

for _, project in ipairs(project_sessions) do
  rex.bind("ctrl+b>" .. project.key, "territorialize", {
    cwd = project.cwd,
    label = project.label,
  })
end

local config = os.getenv("XDG_CONFIG_HOME") or (home .. "/.config")
local tyrannosession_path = config .. "/rex/tyrannosession-rex.lua"
dofile(tyrannosession_path).setup(tyrannosession_path, project_sessions)

local annotator_path = config .. "/rex/tyrannotator-rex.lua"
dofile(annotator_path).setup(annotator_path)
