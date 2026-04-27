local M = {}

M.options = {
  snippets_dir = vim.fn.stdpath("config") .. "/snippets",
  include_current_ft = true,
  include_all = true,
  filter_current_ft = false,
  preview = true,
  cache = true,
  cache_autocmd = true,
  keys = {
    refresh = "<C-r>",
    back = "<BS>",
    back_alt = "x",
    open_split_preview = "<C-p>",
  },
  show_hints = true,
}

function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", M.options, opts or {})
end

return M
