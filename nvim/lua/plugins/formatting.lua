local M = {}

local function options()
  local oxlint_configs = { 'oxlint.config.ts', 'oxlint.config.mts', 'oxlint.config.js', 'oxlint.config.mjs', '.oxlintrc.json', '.oxlintrc.jsonc' }
  local oxfmt_configs = { '.oxfmtrc.json', '.oxfmtrc.jsonc', 'oxfmt.config.ts', 'oxfmt.config.mts' }
  local util = require 'conform.util'

  local function script_formatters(bufnr)
    local formatters = {}
    for _, name in ipairs { 'oxlint', 'oxfmt' } do
      if require('conform').get_formatter_info(name, bufnr).available then
        table.insert(formatters, name)
      end
    end
    -- Run fixes then formatting; otherwise keep the existing fallback.
    return #formatters > 0 and formatters or { 'eslint_d', 'prettierd', 'prettier', stop_after_first = true }
  end

  local document_formatters = { 'oxfmt', 'prettierd', 'prettier', stop_after_first = true }

  return {
    notify_on_error = false,
    format_on_save = function(bufnr)
      -- Disable "format_on_save lsp_fallback" for languages that don't
      -- have a well standardized coding style. You can add additional
      -- languages here or re-enable it for the disabled ones.
      local disable_filetypes = { c = true, cpp = true, java = true }
      if disable_filetypes[vim.bo[bufnr].filetype] then
        return nil
      else
        return {
          timeout_ms = 2000,
          lsp_format = 'fallback',
        }
      end
    end,
    formatters = {
      oxlint = {
        cwd = util.root_file(oxlint_configs),
        require_cwd = true,
        -- Unfixable lint findings still exit 1; keep fixes and continue to Oxfmt.
        exit_codes = { 0, 1 },
      },
      oxfmt = {
        cwd = util.root_file(oxfmt_configs),
        require_cwd = true,
      },
      eslint_d = {
        condition = function(_, ctx)
          local config = vim.fs.find({
            'eslint.config.js',
            'eslint.config.mjs',
            'eslint.config.cjs',
            'eslint.config.ts',
            'eslint.config.mts',
            'eslint.config.cts',
            '.eslintrc',
            '.eslintrc.js',
            '.eslintrc.cjs',
            '.eslintrc.json',
            '.eslintrc.yaml',
            '.eslintrc.yml',
          }, { path = ctx.dirname, upward = true })[1]

          return config ~= nil
        end,
      },
    },
    formatters_by_ft = {
      lua = { 'stylua' },
      python = { 'isort', 'ruff_format' },
      json = document_formatters,
      jsonc = document_formatters,
      javascript = script_formatters,
      javascriptreact = script_formatters,
      typescript = script_formatters,
      typescriptreact = script_formatters,
      yaml = document_formatters,
      markdown = document_formatters,
      html = document_formatters,
      css = document_formatters,
    },
  }
end

function M.setup()
  require('conform').setup(options())
  vim.keymap.set('', '<leader>f', function()
    require('conform').format { async = true, lsp_format = 'fallback' }
  end, { desc = '[F]ormat buffer' })
end

return M
