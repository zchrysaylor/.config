rex.bind("ctrl+b>c", "new_project_tab")
rex.bind("cmd+t", "new_project_tab")
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

rex.action{
  name = "open_project_session",
  title = "Open Project Session",
  category = "Session",
  args = { cwd = "string", label = "string" },
  run = function(_, args)
    local listed, err = rex.call("session.list")
    if listed == nil then error(err, 0) end

    for _, session in ipairs(listed.sessions or {}) do
      if session.label == args.label then
        rex.client.queue("session.select", { session_id = session.session_id })
        return { session_id = session.session_id, created = false }
      end
    end

    -- Rex otherwise falls back to $HOME when cwd doesn't exist.
    local directory, directory_err = rex.exec({ "/bin/test", "-d", args.cwd })
    if directory == nil then error(directory_err, 0) end
    if not directory.ok then error("Directory does not exist: " .. args.cwd, 0) end

    local created, create_err = rex.call("session.create", {
      label = args.label,
      initial_windows = {
        {
          window_label = "pi",
          layout = {
            block = {
              flavor = "com.superlogical.terminal.shell",
              options = { cwd = args.cwd, shell = "/bin/zsh", initial_input = "pi\n" },
            },
          },
        },
        {
          window_label = "zsh",
          layout = {
            block = {
              flavor = "com.superlogical.terminal.shell",
              options = { cwd = args.cwd, shell = "/bin/zsh" },
            },
          },
        },
      },
    })
    if created == nil then error(create_err, 0) end

    rex.client.queue("session.select", {
      session_id = created.session_id,
      window_id = created.initial_windows[2].window_id,
    })
    return { session_id = created.session_id, created = true }
  end,
}

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
  rex.bind("ctrl+b>" .. project.key, "open_project_session", {
    cwd = project.cwd,
    label = project.label,
  })
end

rex.action{
  name = "new_project_tab",
  title = "New Tab at Project Root",
  category = "Tab",
  run = function(ctx)
    if ctx.session_id == nil then
      rex.client.queue("client.tab.new")
      return
    end

    local view, view_err = rex.session.view{ session_id = ctx.session_id }
    if view == nil then error(view_err, 0) end

    local root
    for _, project in ipairs(project_sessions) do
      if project.label == view.label then
        root = project.cwd
        break
      end
    end

    if root == nil then
      rex.client.queue("client.tab.new")
      return
    end

    local directory, directory_err = rex.exec({ "/bin/test", "-d", root })
    if directory == nil then error(directory_err, 0) end
    if not directory.ok then error("Directory does not exist: " .. root, 0) end

    local window, window_err = rex.session.new_window{
      session_id = ctx.session_id,
      window_label = "zsh",
      focus = true,
      layout = {
        block = {
          flavor = "com.superlogical.terminal.shell",
          options = { cwd = root, shell = "/bin/zsh" },
        },
      },
    }
    if window == nil then error(window_err, 0) end

    rex.client.queue("session.select", {
      session_id = ctx.session_id,
      window_id = window.window_id,
    })
    return { window_id = window.window_id }
  end,
}
