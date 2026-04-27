local M = {}

M.options = {
  snippets_dir = vim.fn.stdpath("config") .. "/snippets",
  include_current_ft = true,
  include_all = true,
}

function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", M.options, opts or {})
end

return M
