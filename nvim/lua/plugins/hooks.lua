local M = {}

local function run_build(path, command)
  local result = vim.system(command, { cwd = path }):wait()
  if result.code ~= 0 then
    local message = result.stderr ~= '' and result.stderr or result.stdout
    vim.notify(('Plugin build failed (%s):\n%s'):format(table.concat(command, ' '), message), vim.log.levels.ERROR)
  end
end

function M.setup()
  -- This must be registered before the first vim.pack.add() so it also runs
  -- when plugins are restored from nvim-pack-lock.json on a fresh machine.
  vim.api.nvim_create_autocmd('PackChanged', {
    group = vim.api.nvim_create_augroup('user-vim-pack-hooks', { clear = true }),
    callback = function(event)
      local name, kind = event.data.spec.name, event.data.kind
      if kind ~= 'install' and kind ~= 'update' then
        return
      end

      if name == 'telescope-fzf-native.nvim' and vim.fn.executable 'make' == 1 then
        run_build(event.data.path, { 'make' })
      elseif name == 'LuaSnip' and vim.fn.has 'win32' ~= 1 and vim.fn.executable 'make' == 1 then
        run_build(event.data.path, { 'make', 'install_jsregexp' })
      elseif name == 'nvim-treesitter' then
        -- The :TSUpdate command is created by this plugin's plugin/ script,
        -- so load the updated plugin before invoking it.
        if not event.data.active then
          vim.cmd.packadd 'nvim-treesitter'
        end
        vim.cmd 'TSUpdate'
      end
    end,
  })
end

return M
