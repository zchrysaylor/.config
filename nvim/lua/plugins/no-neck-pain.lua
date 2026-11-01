local M = {}

function M.setup()
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
  }
end

return M
