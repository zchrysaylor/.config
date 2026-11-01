local M = {}

function M.setup()
  -- Mason sets its PATH and commands before tools and language servers start.
  require('mason').setup {}

  require('lazydev').setup {
    library = {
      { path = '${3rd}/luv/library', words = { 'vim%.uv' } },
    },
  }

  require('fidget').setup {
    progress = {
      suppress_on_insert = true,
      display = {
        format_message = function(message)
          if message.lsp_client.name == 'jdtls' then
            return ''
          end
          return require('fidget.progress.display').default_format_message(message)
        end,
        format_annote = function(message)
          if message.lsp_client.name == 'jdtls' then
            return ''
          end
          return message.title
        end,
      },
    },
    notification = {
      view = {
        render_message = function(message, count)
          if message == '' then
            return ''
          end
          return count == 1 and message or string.format('(%dx) %s', count, message)
        end,
      },
    },
  }
end

return M
