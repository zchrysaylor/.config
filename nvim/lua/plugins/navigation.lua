local M = {}

function M.setup()
  -- Telescope LSP pickers override Neovim's default LSP navigation mappings.
  local builtin = require 'telescope.builtin'
  vim.api.nvim_create_autocmd('LspAttach', {
    group = vim.api.nvim_create_augroup('telescope-lsp-attach', { clear = true }),
    callback = function(event)
      local opts = { buffer = event.buf }
      vim.keymap.set('n', 'grr', builtin.lsp_references, vim.tbl_extend('force', opts, { desc = '[G]oto [R]eferences' }))
      vim.keymap.set('n', 'gri', builtin.lsp_implementations, vim.tbl_extend('force', opts, { desc = '[G]oto [I]mplementation' }))
      vim.keymap.set('n', 'grd', builtin.lsp_definitions, vim.tbl_extend('force', opts, { desc = '[G]oto [D]efinition' }))
      vim.keymap.set('n', 'gO', builtin.lsp_document_symbols, vim.tbl_extend('force', opts, { desc = 'Open Document Symbols' }))
      vim.keymap.set('n', 'gW', builtin.lsp_dynamic_workspace_symbols, vim.tbl_extend('force', opts, { desc = 'Open Workspace Symbols' }))
      vim.keymap.set('n', 'grt', builtin.lsp_type_definitions, vim.tbl_extend('force', opts, { desc = '[G]oto [T]ype Definition' }))
    end,
  })

  vim.keymap.set('n', '<leader>/', function()
    require('telescope.builtin').current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
      winblend = 10,
      previewer = false,
    })
  end, { desc = '[/] Fuzzily search in current buffer' })

  vim.keymap.set('n', '<leader>s/', function()
    require('telescope.builtin').live_grep {
      grep_open_files = true,
      prompt_title = 'Live Grep in Open Files',
    }
  end, { desc = '[S]earch [/] in Open Files' })

  vim.keymap.set('n', '<leader>sn', function()
    require('telescope.builtin').find_files { cwd = vim.fn.stdpath 'config' }
  end, { desc = '[S]earch [N]eovim files' })
end

return M
