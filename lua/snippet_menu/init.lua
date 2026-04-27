local M = {}

function M.setup(opts)
  require("snippet_menu.config").setup(opts)
end

function M.open()
  require("snippet_menu.picker").open()
end

return M
