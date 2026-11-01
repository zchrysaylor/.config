local M = {}

function M.setup()
  require('java').setup()
  vim.lsp.config('jdtls', {
    settings = {
      java = {
        completion = {
          importOrder = { 'java', 'javax', 'jakarta', 'org', 'com', '' },
        },
        format = {
          enabled = true,
          settings = {
            url = vim.fn.expand '~/Code/IdeaProjects/deliveryhero/log-vendor-order-management-application/resources/ide/eclipse/java-codestyle-formatter.xml',
            profile = 'CodeFormatterProfile',
          },
        },
        saveActions = {
          organizeImports = true,
        },
        sources = {
          organizeImports = {
            starThreshold = 99,
            staticStarThreshold = 99,
          },
        },
      },
    },
  })
  vim.lsp.enable 'jdtls'
end

return M
