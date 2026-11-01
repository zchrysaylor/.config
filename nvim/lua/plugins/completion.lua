local M = {}

function M.setup()
  require('blink.cmp').setup {
    keymap = {
      -- The default preset uses <c-y> to accept and supports snippet navigation.
      preset = 'default',
    },
    appearance = {
      nerd_font_variant = 'normal',
    },
    completion = {
      documentation = { auto_show = false, auto_show_delay_ms = 500 },
    },
    sources = {
      default = { 'lsp', 'path', 'snippets' },
    },
    snippets = { preset = 'luasnip' },
    fuzzy = { implementation = 'lua' },
    signature = { enabled = true },
  }
end

return M
