local M = {}

function M.setup()
  local group = vim.api.nvim_create_augroup('nnp-first-edit', { clear = true })
  local armed = true
  local pending = false

  local function is_work_buffer()
    if vim.api.nvim_win_get_config(0).relative ~= '' then
      return false
    end

    return vim.bo.filetype == 'oil'
      or (vim.bo.buftype == '' and (vim.api.nvim_buf_get_name(0) ~= '' or vim.bo.modified))
  end

  require('no-neck-pain').setup {
    width = 128,
    minSideBufferWidth = 10,
    mappings = {
      enabled = true,
      toggle = '<leader>np',
    },
    buffers = {
      scratchPad = { enabled = false },
      wo = {
        fillchars = 'eob: ',
        statusline = ' ',
      },
    },
    autocmds = {
      enableOnVimEnter = false,
      enableOnTabEnter = false,
      reloadOnColorSchemeChange = true,
      skipEnteringNoNeckPainBuffer = true,
    },
    callbacks = {
      postEnable = function()
        -- Manual activation also consumes the one-shot, so later toggles stay respected.
        armed = false
        vim.api.nvim_clear_autocmds { group = group }
      end,
    },
  }

  -- Observe actual work, not keys, InsertEnter, or Telescope's temporary buffers.
  -- Leaving the initial empty buffer untouched preserves Neovim's native intro.
  vim.api.nvim_create_autocmd({
    'VimEnter',
    'BufEnter',
    'BufWinEnter',
    'BufFilePost',
    'FileType',
    'TextChanged',
    'TextChangedI',
    'TextChangedP',
  }, {
    group = group,
    desc = 'Enable NoNeckPain once a file, directory, or edited buffer is active',
    callback = function()
      if not armed or pending or vim.v.vim_did_enter == 0 or not is_work_buffer() then
        return
      end

      -- Let startup, filetype detection, and picker window transitions finish first.
      pending = true
      vim.schedule(function()
        pending = false
        if armed and is_work_buffer() then
          require('no-neck-pain').enable 'first-edit'
        end
      end)
    end,
  })
end

return M
